import unicodedata
from datetime import datetime

import requests
from bs4 import BeautifulSoup

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from waateaapp.models import HistoricalGame
from waatea_2.users.models import UserProfile


SPORTLOMO_BASE_URL = "https://fsr.sportlomo.com"
SPORTLOMO_AJAX_URL = f"{SPORTLOMO_BASE_URL}/wp-admin/admin-ajax.php"


def normalize_text(value):
    """
    Normalize text received from SportLoMo.

    Unicode and whitespace are normalized, but accents and spelling
    are deliberately retained.
    """
    if value is None:
        return ""

    value = unicodedata.normalize("NFC", str(value))
    value = value.replace("\xa0", " ")

    return " ".join(value.split()).strip()


def normalize_player_name(value):
    """
    Convert federation player names into a canonical representation.

    Handles:
      - old Lastname Firstname-Secondname format
      - new Firstname Secondname Lastname format
      - case differences
      - accents/diacritics, e.g. Raphaël vs Raphael
      - whitespace differences
    """
    value = normalize_text(value)

    # Remove accents/diacritics for comparison only.
    value = "".join(
        char
        for char in unicodedata.normalize("NFD", value)
        if unicodedata.category(char) != "Mn"
    )

    # Old federation data used hyphens between multiple first names.
    value = value.replace("-", " ")

    parts = [
        part.casefold()
        for part in value.split()
        if part
    ]

    return tuple(sorted(parts))


class Command(BaseCommand):
    help = "Import historical caps from SportLoMo team sheets"

    def add_arguments(self, parser):
        parser.add_argument(
            "competition_id",
            type=str,
            help="SportLoMo competition/league ID, e.g. 208469",
        )

        parser.add_argument(
            "team_name",
            type=str,
            help=(
                "Exact SportLoMo team name, "
                'e.g. "Rugby Club Winterthur"'
            ),
        )

        parser.add_argument(
            "--dry-run",
            action="store_true",
            help=(
                "Parse and match everything without writing "
                "to the database"
            ),
        )

    def handle(self, *args, **options):
        competition_id = options["competition_id"]
        team_name = normalize_text(options["team_name"])
        dry_run = options["dry_run"]

        self.stdout.write(
            f"SportLoMo competition: {competition_id}"
        )
        self.stdout.write(
            f"Team: {team_name}"
        )

        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    "DRY RUN - database will not be modified"
                )
            )

        fixtures = self.get_fixtures(
            competition_id=competition_id,
            team_name=team_name,
        )

        if not fixtures:
            raise CommandError(
                f'No fixtures found for exact team "{team_name}" '
                f"in competition {competition_id}"
            )

        self.stdout.write(
            f"\nFound {len(fixtures)} fixtures for {team_name}\n"
        )

        total_found = 0
        total_matched = 0
        total_imported = 0
        total_existing = 0
        total_unmatched = 0
        total_no_teamsheet = 0

        for fixture in fixtures:
            result = self.import_fixture(
                fixture=fixture,
                team_name=team_name,
                dry_run=dry_run,
            )

            total_found += result["found"]
            total_matched += result["matched"]
            total_imported += result["imported"]
            total_existing += result["existing"]
            total_unmatched += result["unmatched"]

            if result["no_teamsheet"]:
                total_no_teamsheet += 1

        self.stdout.write("")
        self.stdout.write("=" * 60)
        self.stdout.write("IMPORT SUMMARY")
        self.stdout.write("=" * 60)

        self.stdout.write(
            f"Fixtures:          {len(fixtures)}"
        )
        self.stdout.write(
            f"No teamsheet:      {total_no_teamsheet}"
        )
        self.stdout.write(
            f"Players found:     {total_found}"
        )
        self.stdout.write(
            f"Players matched:   {total_matched}"
        )

        if dry_run:
            self.stdout.write(
                f"Would import:      {total_imported}"
            )
        else:
            self.stdout.write(
                f"Imported:          {total_imported}"
            )

        self.stdout.write(
            f"Already present:   {total_existing}"
        )
        self.stdout.write(
            f"Unmatched players: {total_unmatched}"
        )

        if total_unmatched:
            self.stdout.write(
                self.style.WARNING(
                    "\nImport completed with unmatched players."
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    "\nImport completed successfully."
                )
            )

    def get_fixtures(
        self,
        competition_id,
        team_name,
    ):
        """
        Fetch the SportLoMo league page and return all fixtures involving
        exactly team_name.

        SportLoMo provides the useful metadata directly as data attributes:

            data-date
            data-hometeam
            data-awayteam
            data-compname

        The fixture ID is stored on the child .fmore element as data-fid.
        """

        url = (
            f"{SPORTLOMO_BASE_URL}/league/"
            f"{competition_id}/"
        )

        self.stdout.write(
            f"\nFetching league page: {url}"
        )

        try:
            response = requests.get(
                url,
                timeout=30,
                headers={
                    "User-Agent": (
                        "Waatea SportLoMo importer"
                    ),
                },
            )

            response.raise_for_status()

        except requests.RequestException as exc:
            raise CommandError(
                f"Could not fetch SportLoMo league page: {exc}"
            ) from exc

        soup = BeautifulSoup(
            response.text,
            "html.parser",
        )

        fixtures = []
        seen_fixture_ids = set()

        selector = (
            f"ul.table-body.results-{competition_id}"
        )

        for row in soup.select(selector):
            home_team = normalize_text(
                row.get("data-hometeam")
            )
            away_team = normalize_text(
                row.get("data-awayteam")
            )

            # Exact comparison is intentional.
            #
            # This prevents the men's team from accidentally matching
            # women's or Entente teams containing "Winterthur".
            if team_name not in (
                home_team,
                away_team,
            ):
                continue

            fixture_element = row.select_one(
                ".fmore[data-fid]"
            )

            if fixture_element is None:
                self.stderr.write(
                    self.style.WARNING(
                        f"Skipping {home_team} - "
                        f"{away_team}: "
                        "no fixture ID found."
                    )
                )
                continue

            fixture_id = normalize_text(
                fixture_element.get("data-fid")
            )

            if not fixture_id:
                continue

            # SportLoMo contains the .fmore element twice:
            # once for desktop and once for mobile.
            if fixture_id in seen_fixture_ids:
                continue

            seen_fixture_ids.add(
                fixture_id
            )

            date_string = normalize_text(
                row.get("data-date")
            )

            if not date_string:
                self.stderr.write(
                    self.style.WARNING(
                        f"Skipping fixture {fixture_id}: "
                        "no date found."
                    )
                )
                continue

            try:
                fixture_date = datetime.strptime(
                    date_string,
                    "%d %b %Y",
                )
            except ValueError:
                self.stderr.write(
                    self.style.WARNING(
                        f"Skipping fixture {fixture_id}: "
                        f'cannot parse date "{date_string}".'
                    )
                )
                continue

            # HistoricalGame.date is a DateTimeField.
            #
            # Use midday so timezone conversion cannot accidentally
            # move the match to another calendar day.
            fixture_date = fixture_date.replace(
                hour=12,
                minute=0,
                second=0,
                microsecond=0,
            )

            fixture_date = timezone.make_aware(
                fixture_date,
                timezone.get_current_timezone(),
            )

            competition = normalize_text(
                row.get("data-compname")
            )

            fixtures.append(
                {
                    "id": fixture_id,
                    "home": home_team,
                    "away": away_team,
                    "date": fixture_date,
                    "competition": competition,
                }
            )

        fixtures.sort(
            key=lambda fixture: fixture["date"]
        )

        return fixtures

    def get_team_sheet(
        self,
        fixture,
    ):
        """
        Fetch the fixture information from SportLoMo.

        This is the same AJAX request made by the website when the user
        clicks "Team sheet".
        """

        try:
            response = requests.post(
                SPORTLOMO_AJAX_URL,
                timeout=30,
                headers={
                    "User-Agent": (
                        "Waatea SportLoMo importer"
                    ),
                    "X-Requested-With": (
                        "XMLHttpRequest"
                    ),
                },
                data={
                    "action": "fixtureInformation",
                    "hometeam": fixture["home"],
                    "awayteam": fixture["away"],
                    "id": fixture["id"],
                },
            )

            response.raise_for_status()

        except requests.RequestException as exc:
            raise CommandError(
                f'Could not fetch teamsheet for fixture '
                f'{fixture["id"]}: {exc}'
            ) from exc

        return response.text

    def parse_team_sheet(
        self,
        html,
        team_name,
    ):
        """
        Extract every player listed for exactly team_name.

        Returns:

            [
                (1, "Pascal Engelhard"),
                (2, "Beat Martin Gutzwiller"),
                ...
            ]

        Every listed player counts as one cap. Starters and replacements
        are deliberately treated the same.
        """

        soup = BeautifulSoup(
            html,
            "html.parser",
        )

        for team_block in soup.select(
            ".hometeam_ul, .awyteam_ul"
        ):
            heading = team_block.select_one(
                ".preivoue_ul .colored"
            )

            if heading is None:
                continue

            found_team_name = normalize_text(
                heading.get_text(
                    " ",
                    strip=True,
                )
            )

            # Exact comparison is intentional.
            if found_team_name != team_name:
                continue

            players = []

            for row in team_block.select(
                "ol.name_player > li"
            ):
                number_element = row.find("b")

                if number_element is None:
                    continue

                position_text = normalize_text(
                    number_element.get_text()
                )

                try:
                    position = int(
                        position_text
                    )
                except ValueError:
                    self.stderr.write(
                        self.style.WARNING(
                            f'Invalid position '
                            f'"{position_text}" '
                            f"on teamsheet for "
                            f"{team_name}."
                        )
                    )
                    continue

                player_name_parts = []

                for content in row.contents:
                    if content == number_element:
                        continue

                    if getattr(
                        content,
                        "get_text",
                        None,
                    ):
                        text = content.get_text(
                            " ",
                            strip=True,
                        )
                    else:
                        text = str(content)

                    text = normalize_text(
                        text
                    )

                    if text:
                        player_name_parts.append(
                            text
                        )

                player_name = normalize_text(
                    " ".join(
                        player_name_parts
                    )
                )

                if not player_name:
                    continue

                players.append(
                    (
                        position,
                        player_name,
                    )
                )

            return players

        return []

    def find_player(
        self,
        federation_name,
    ):
        """
        Match a current SportLoMo teamsheet name against
        UserProfile.sportlomo_id.

        Despite the legacy field name, sportlomo_id contains the
        federation teamsheet name.

        The old source used:

            Lastname Firstname-Secondname

        while the current SportLoMo source uses:

            Firstname Secondname Lastname

        Therefore we first try an exact match, then compare canonical
        collections of name components.

        Matching is deliberately conservative. We do not fuzzy-match
        missing or misspelled names.
        """

        # Fast path: exact value already matches.
        matches = list(
            UserProfile.objects
            .select_related("user")
            .filter(
                sportlomo_id=federation_name
            )
        )

        if len(matches) == 1:
            return matches[0].user

        if len(matches) > 1:
            raise CommandError(
                f'Multiple UserProfiles have sportlomo_id '
                f'"{federation_name}".'
            )

        wanted_name = normalize_player_name(
            federation_name
        )

        normalized_matches = []

        profiles = (
            UserProfile.objects
            .select_related("user")
            .exclude(sportlomo_id="")
        )

        for profile in profiles:
            database_name = (
                profile.sportlomo_id
            )

            if (
                normalize_player_name(
                    database_name
                )
                == wanted_name
            ):
                normalized_matches.append(
                    profile
                )

        if len(normalized_matches) == 1:
            return (
                normalized_matches[0]
                .user
            )

        if len(normalized_matches) > 1:
            database_names = ", ".join(
                profile.sportlomo_id
                for profile
                in normalized_matches
            )

            raise CommandError(
                f'Ambiguous federation name '
                f'"{federation_name}". '
                f"Matches: {database_names}"
            )

        return None

    def import_fixture(
        self,
        fixture,
        team_name,
        dry_run,
    ):
        """
        Import all players listed on one fixture teamsheet.
        """

        self.stdout.write("")
        self.stdout.write(
            "-" * 60
        )

        self.stdout.write(
            f'{fixture["date"].date()}  '
            f'{fixture["home"]} - '
            f'{fixture["away"]}'
        )

        self.stdout.write(
            f'Fixture ID: {fixture["id"]}'
        )

        if fixture["competition"]:
            self.stdout.write(
                f'Competition: '
                f'{fixture["competition"]}'
            )

        html = self.get_team_sheet(
            fixture
        )

        players = self.parse_team_sheet(
            html=html,
            team_name=team_name,
        )

        if not players:
            self.stdout.write(
                self.style.WARNING(
                    "No teamsheet/players found "
                    "for this fixture."
                )
            )

            return {
                "found": 0,
                "matched": 0,
                "imported": 0,
                "existing": 0,
                "unmatched": 0,
                "no_teamsheet": True,
            }

        self.stdout.write(
            f"{len(players)} players on teamsheet:"
        )

        result = {
            "found": len(players),
            "matched": 0,
            "imported": 0,
            "existing": 0,
            "unmatched": 0,
            "no_teamsheet": False,
        }

        if fixture["home"] == team_name:
            played_against = (
                fixture["away"]
            )
        else:
            played_against = (
                fixture["home"]
            )

        competition = (
            fixture["competition"]
        )

        with transaction.atomic():
            for (
                position,
                federation_name,
            ) in players:
                player = self.find_player(
                    federation_name
                )

                if player is None:
                    result["unmatched"] += 1

                    self.stdout.write(
                        self.style.ERROR(
                            f"  ✗ {position:>2}  "
                            f"{federation_name} "
                            "[NOT FOUND]"
                        )
                    )

                    continue

                result["matched"] += 1

                existing = (
                    HistoricalGame.objects
                    .filter(
                        played_for=team_name,
                        played_against=played_against,
                        date=fixture["date"],
                        player=player,
                    )
                    .first()
                )

                if existing is not None:
                    result["existing"] += 1

                    self.stdout.write(
                        f"  = {position:>2}  "
                        f"{federation_name} "
                        "[already imported]"
                    )

                    continue

                if dry_run:
                    result["imported"] += 1

                    self.stdout.write(
                        self.style.SUCCESS(
                            f"  ✓ {position:>2}  "
                            f"{federation_name} "
                            "[would import]"
                        )
                    )

                    continue

                HistoricalGame.objects.create(
                    played_for=team_name,
                    played_against=played_against,
                    player=player,
                    date=fixture["date"],
                    position=str(position),
                    competition=competition,
                )

                result["imported"] += 1

                self.stdout.write(
                    self.style.SUCCESS(
                        f"  ✓ {position:>2}  "
                        f"{federation_name}"
                    )
                )

            # Extra safety: even if something above accidentally writes
            # during a dry run, roll the entire transaction back.
            if dry_run:
                transaction.set_rollback(
                    True
                )

        return result
