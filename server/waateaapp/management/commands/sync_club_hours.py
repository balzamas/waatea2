# users/management/commands/sync_club_hours.py
import os
from django.core.management.base import BaseCommand, CommandError
from integrations.helfereinsatz import sync_club_hours_from_helpers

class Command(BaseCommand):
    help = "Syncs club_hours (stateCache.plannedValue) from Helfereinsatz into UserProfile.club_hours"

    def add_arguments(self, parser):
        parser.add_argument("--api-key", help="X-API-KEY for Helfereinsatz API (default: env HELFEREINSATZ_API_KEY)")
        parser.add_argument("--slug", help="Club slug, e.g. 'rugby-winterthur' (default: env HELFEREINSATZ_SLUG or 'rugby-winterthur')")
        parser.add_argument("--base-url", help="Base URL (default: env HELFEREINSATZ_BASE or https://api.helfereinsatz.ch/v1)")

    def handle(self, *args, **opts):
        api_key = opts.get("api_key") or os.getenv("HELFEREINSATZ_API_KEY")
        slug = opts.get("slug") or os.getenv("HELFEREINSATZ_SLUG") or "rugby-winterthur"
        base_url = opts.get("base_url") or os.getenv("HELFEREINSATZ_BASE") or "https://api.helfereinsatz.ch/v1"

        if not api_key:
            raise CommandError("Missing API key. Provide --api-key or set HELFEREINSATZ_API_KEY.")

        res = sync_club_hours_from_helpers(api_key=api_key, slug=slug, base_url=base_url)
        self.stdout.write(self.style.SUCCESS(f"Sync completed: {res}"))
