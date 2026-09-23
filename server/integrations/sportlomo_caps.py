import unicodedata
from datetime import datetime

import requests
from bs4 import BeautifulSoup

from django.db import transaction
from django.utils import timezone

from waateaapp.models import HistoricalGame
from waatea_2.users.models import UserProfile


SPORTLOMO_BASE_URL = "https://fsr.sportlomo.com"
SPORTLOMO_AJAX_URL = f"{SPORTLOMO_BASE_URL}/wp-admin/admin-ajax.php"


def normalize_text(value):
    """
    Normalize text received from SportLoMo.

    Unicode and whitespace are normalized, but the actual spelling
    is otherwise retained.
    """
    if value is None:
        return ""

    value = unicodedata.normalize("NFC", str(value))
    value = value.replace("\xa0", " ")

    return " ".join(value.split()).strip()


def normalize_player_name(value):
    """
    Convert federation player names into a canonical representation.

    Handles differences between the old federation source and the
    current SportLoMo teamsheets.

    Examples:

        Blumer David-Sebastian
        David Sebastian Blumer

    both become:

        ("blumer", "david", "sebastian")

    Also handles accents:

        Vonlanthen Raphaël
        Raphael Vonlanthen

    both become:

        ("raphael", "vonlanthen")

    This is deliberately not fuzzy matching. All name components
    still have to match.
    """
    value = normalize_text(value)

    # Remove accents/diacritics for comparison only.
    value = "".join(
        char
        for char in unicodedata.normalize("NFD", value)
        if unicodedata.category(char) != "Mn"
    )

    # The old source used hyphens between multiple first names.
    value = value.replace("-", " ")

    parts = [
        part.casefold()
        for part in value.split()
        if part
    ]

    return tuple(sorted(parts))


def get_fixtures(competition_id, team_name):
    """
    Fetch the SportLoMo league page and return all fixtures involving
    exactly team_name.
    """

    url = (
        f"{SPORTLOMO_BASE_URL}/league/"
        f"{competition_id}/"
    )

    response = requests.get(
        url,
        timeout=30,
        headers={
            "User-Agent": "Waatea SportLoMo importer",
        },
    )

    response.raise_for_status()

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

        # Exact matching is intentional.
        #
        # This prevents Rugby Club Winterthur from accidentally
        # matching another Winterthur women's/Entente team.
        if team_name not in (
            home_team,
            away_team,
        ):
            continue

        fixture_element = row.select_one(
            ".fmore[data-fid]"
        )

        if fixture_element is None:
            continue

        fixture_id = normalize_text(
            fixture_element.get("data-fid")
        )

        if not fixture_id:
            continue

        # SportLoMo contains the fmore element twice:
        # desktop and mobile.
        if fixture_id in seen_fixture_ids:
            continue

        seen_fixture_ids.add(
            fixture_id
        )

        date_string = normalize_text(
            row.get("data-date")
        )

        if not date_string:
            continue

        try:
            fixture_date = datetime.strptime(
                date_string,
                "%d %b %Y",
            )
        except ValueError:
            continue

        # HistoricalGame.date is a DateTimeField.
        #
        # Midday avoids timezone conversion accidentally changing
        # the calendar date.
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


def get_team_sheet(fixture):
    """
    Fetch the fixture-information popup from SportLoMo.

    This is the same AJAX request made by SportLoMo when clicking
    "Team sheet".
    """

    response = requests.post(
        SPORTLOMO_AJAX_URL,
        timeout=30,
        headers={
            "User-Agent": "Waatea SportLoMo importer",
            "X-Requested-With": "XMLHttpRequest",
        },
        data={
            "action": "fixtureInformation",
            "hometeam": fixture["home"],
            "awayteam": fixture["away"],
            "id": fixture["id"],
        },
    )

    response.raise_for_status()

    return response.text


def parse_team_sheet(html, team_name):
    """
    Extract every player listed for exactly team_name.

    Returns:

        [
            (1, "Pascal Engelhard"),
            (2, "Beat Martin Gutzwiller"),
            ...
        ]

    Every listed player counts as one cap.
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


def find_player(federation_name):
    """
    Match the current SportLoMo name against UserProfile.sportlomo_id.

    The old source used:

        Lastname Firstname-Secondname

    SportLoMo now uses:

        Firstname Secondname Lastname

    We first try an exact match and then use normalized name
    components.

    Returns the User object or None.

    Raises ValueError if more than one profile matches.
    """

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
        raise ValueError(
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
        if (
            normalize_player_name(
                profile.sportlomo_id
            )
            == wanted_name
        ):
            normalized_matches.append(
                profile
            )

    if len(normalized_matches) == 1:
        return normalized_matches[0].user

    if len(normalized_matches) > 1:
        database_names = ", ".join(
            profile.sportlomo_id
            for profile in normalized_matches
        )

        raise ValueError(
            f'Ambiguous federation name '
            f'"{federation_name}". '
            f"Matches: {database_names}"
        )

    return None


def import_sportlomo_caps(
    competition_id,
    team_name,
    dry_run=False,
):
    """
    Import caps from all SportLoMo fixtures for a competition/team.

    This function is shared by:
        - the Django management command
        - the Django admin interface

    Returns a structured result dictionary suitable for both CLI
    output and Django admin messages.
    """

    competition_id = normalize_text(
        competition_id
    )

    team_name = normalize_text(
        team_name
    )

    fixtures = get_fixtures(
        competition_id=competition_id,
        team_name=team_name,
    )

    result = {
        "fixtures": len(fixtures),
        "no_teamsheet": 0,
        "players_found": 0,
        "matched": 0,
        "imported": 0,
        "would_import": 0,
        "existing": 0,
        "unmatched": [],
        "fixture_results": [],
    }

    for fixture in fixtures:
        html = get_team_sheet(
            fixture
        )

        players = parse_team_sheet(
            html=html,
            team_name=team_name,
        )

        opponent = (
            fixture["away"]
            if fixture["home"] == team_name
            else fixture["home"]
        )

        fixture_result = {
            "fixture_id": fixture["id"],
            "date": fixture["date"],
            "home": fixture["home"],
            "away": fixture["away"],
            "competition": fixture["competition"],
            "players_found": len(players),
            "matched": 0,
            "imported": 0,
            "would_import": 0,
            "existing": 0,
            "unmatched": [],
        }

        if not players:
            result["no_teamsheet"] += 1

            fixture_result["no_teamsheet"] = True

            result["fixture_results"].append(
                fixture_result
            )

            continue

        fixture_result["no_teamsheet"] = False

        result["players_found"] += len(
            players
        )

        with transaction.atomic():
            for (
                position,
                federation_name,
            ) in players:
                player = find_player(
                    federation_name
                )

                if player is None:
                    unmatched = {
                        "name": federation_name,
                        "position": position,
                        "fixture_id": fixture["id"],
                        "date": fixture["date"].date(),
                        "opponent": opponent,
                    }

                    result["unmatched"].append(
                        unmatched
                    )

                    fixture_result[
                        "unmatched"
                    ].append(
                        unmatched
                    )

                    continue

                result["matched"] += 1
                fixture_result["matched"] += 1

                existing = (
                    HistoricalGame.objects
                    .filter(
                        played_for=team_name,
                        played_against=opponent,
                        date=fixture["date"],
                        player=player,
                    )
                    .first()
                )

                if existing is not None:
                    result["existing"] += 1

                    fixture_result[
                        "existing"
                    ] += 1

                    continue

                if dry_run:
                    result["would_import"] += 1

                    fixture_result[
                        "would_import"
                    ] += 1

                    continue

                HistoricalGame.objects.create(
                    played_for=team_name,
                    played_against=opponent,
                    player=player,
                    date=fixture["date"],
                    position=str(position),
                    competition=fixture[
                        "competition"
                    ],
                )

                result["imported"] += 1

                fixture_result[
                    "imported"
                ] += 1

            if dry_run:
                transaction.set_rollback(
                    True
                )

        result["fixture_results"].append(
            fixture_result
        )

    return result
