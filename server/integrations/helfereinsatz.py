# integrations/helfereinsatz.py
import logging
import requests
from decimal import Decimal, InvalidOperation
from typing import Dict, Any, Iterable, List, Optional

from django.db import transaction
from django.contrib.auth import get_user_model

# Passe den Import-Pfad an dein Projekt an:
from waatea_2.users.models import UserProfile  # z.B. apps/users/models.py

logger = logging.getLogger(__name__)
User = get_user_model()


class HelfereinsatzClient:
    """
    Kleiner API-Client für:
    GET https://api.helfereinsatz.ch/v1/{slug}/helpers/{pageNo}
    Header:
      X-API-KEY: <key>
      Accept: application/json
    """
    def __init__(self, api_key: str, slug: str, base_url: str = "https://api.helfereinsatz.ch/v1", timeout: int = 20):
        self.api_key = api_key
        self.slug = slug.strip("/")
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            "X-API-KEY": self.api_key,
            "Accept": "application/json",
        })

    def _url(self, page_no: int) -> str:
        return f"{self.base_url}/{self.slug}/helpers/{page_no}"

    def fetch_page(self, page_no: int) -> Dict[str, Any]:
        resp = self.session.get(self._url(page_no), timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()

    def fetch_all(self) -> Iterable[Dict[str, Any]]:
        """
        Yields einzelne Helper-Objekte (Elements aus 'entries').
        Response-Form laut Beispiel:
        {
          "pageNo": 1,
          "pagesNum": 6,
          "entries": [ {...}, {...} ]
        }
        """
        first = self.fetch_page(1)
        entries = first.get("entries", []) or []
        for e in entries:
            yield e

        pages_num = int(first.get("pagesNum") or 1)
        # Restliche Seiten laden, falls vorhanden
        for page in range(2, pages_num + 1):
            data = self.fetch_page(page)
            for e in data.get("entries", []) or []:
                yield e


def _to_decimal(value: Any) -> Optional[Decimal]:
    """
    Robust decimal parsing: akzeptiert int, float, str (mit , oder .)
    """
    if value is None:
        return None
    if isinstance(value, (int, float, Decimal)):
        return Decimal(str(value))
    if isinstance(value, str):
        try:
            return Decimal(value.replace(",", "."))
        except (InvalidOperation, AttributeError):
            return None
    return None


@transaction.atomic
def sync_club_hours_from_helpers(api_key: str, slug: str = "rugby-winterthur", base_url: str = "https://api.helfereinsatz.ch/v1") -> dict:
    """
    Lädt alle Helfer-Datensätze und schreibt stateCache.plannedValue in UserProfile.club_hours.
    Identifikation per E-Mail: 'email'. (Optional könntest du additionalEmail1/2 als Fallback nutzen.)
    """
    client = HelfereinsatzClient(api_key=api_key, slug=slug, base_url=base_url)

    updated = 0
    skipped_no_user = 0
    skipped_no_email = 0
    skipped_no_value = 0
    errors = 0
    total = 0

    for helper in client.fetch_all():
        total += 1
        try:
            email = (helper.get("email") or "").strip().lower()
            if not email:
                skipped_no_email += 1
                continue

            state_cache = helper.get("stateCache") or {}
            planned_val_dec = _to_decimal(state_cache.get("plannedValue"))

            if planned_val_dec is None:
                skipped_no_value += 1
                continue

            # Wenn plannedValue Minuten darstellen sollte:
            # planned_val_dec = planned_val_dec / Decimal("60")

            try:
                user = User.objects.get(email__iexact=email)
            except User.DoesNotExist:
                skipped_no_user += 1
                continue

            profile, _ = UserProfile.objects.get_or_create(user=user)
            profile.club_hours = float(planned_val_dec)
            profile.save(update_fields=["club_hours"])
            updated += 1

        except Exception:
            logger.exception("Error syncing club_hours for helper=%s", helper)
            errors += 1

    result = {
        "total_rows": total,
        "updated": updated,
        "skipped_no_email": skipped_no_email,
        "skipped_no_user": skipped_no_user,
        "skipped_no_value": skipped_no_value,
        "errors": errors,
    }
    logger.info("Helfereinsatz sync result: %s", result)
    return result
