from uuid import UUID

from django.shortcuts import render, redirect
from .models import Game as GameModel, User, Availability, Club, Attendance, Training
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer, ClubSerializer
from rest_framework import viewsets
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authentication import SessionAuthentication, BasicAuthentication
from django.http import HttpResponse, Http404
from django.utils import timezone
from datetime import timedelta
import hashlib

def _esc(s: str) -> str:
    if s is None:
        return ""
    return (
        str(s)
        .replace("\\", "\\\\")
        .replace(";", "\\;")
        .replace(",", "\\,")
        .replace("\r\n", "\\n")
        .replace("\n", "\\n")
    )

def _to_ics_utc(dt) -> str:
    """aware/naive -> UTC ICS (YYYYMMDDTHHMMSSZ)"""
    if timezone.is_naive(dt):
        dt = timezone.make_aware(dt, timezone.get_current_timezone())
    dt = dt.astimezone(timezone.utc)
    return dt.strftime("%Y%m%dT%H%M%SZ")

def calendar_feed(request, club_id: UUID):
    """
    Abonnierbarer Kalender für einen Club (Spiele, ab jetzt).
    URL: /calendar/club/<club_id>.ics?season=<season_id>
    """
    season_param = request.GET.get("season")  # kann int ODER UUID sein
    # Wenn Season auch UUID ist, kommentier die nächste Zeile ein:
    season_id = UUID(season_param) if season_param else None

    try:
        club = Club.objects.only("name").get(pk=club_id)
    except Club.DoesNotExist:
        raise Http404("Club not found")

    now = timezone.now()

    g_qs = GameModel.objects.filter(
        club_id=club_id,
        season_id=season_id,
        date__gte=now,
    ).order_by("date")

    # Build calendar name/description
    cal_name = f"{club.name} – Game calendar"
    cal_desc = f"Upcoming games for {club.name}"

    # Kopf
    lines = [
        "BEGIN:VCALENDAR",
        "PRODID:-//Waatea//Team Calendar//EN",
        "VERSION:2.0",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        # Display name (Apple/Google recognize X-WR-CALNAME)
        f"X-WR-CALNAME:{_esc(cal_name)}",
        f"X-WR-CALDESC:{_esc(cal_desc)}",
        # Optional: RFC 7986 properties (harmless if ignored)
        f"NAME:{_esc(cal_name)}",
        f"DESCRIPTION:{_esc(cal_desc)}",
        "X-WR-TIMEZONE:Europe/Zurich",
    ]

    nowstamp = _to_ics_utc(now)

    # ------- Spiele (Game hat updated) -------
    GAME_DURATION_MIN = 120
    for g in g_qs:
        uid = f"game-{g.id}@waatea.app"
        dtstart = _to_ics_utc(g.date)
        dtend = _to_ics_utc(g.date + timedelta(minutes=GAME_DURATION_MIN))
        lastmod = _to_ics_utc(g.updated) if g.updated else nowstamp
        summary = f"{g.home.name} vs {g.away.name}"

        lines.extend([
            "BEGIN:VEVENT",
            f"UID:{uid}",
            f"DTSTAMP:{nowstamp}",
            f"LAST-MODIFIED:{lastmod}",
            "SEQUENCE:0",  # optional: später erhöhen, falls du Versionen pflegen willst
            f"DTSTART:{dtstart}",
            f"DTEND:{dtend}",
            f"SUMMARY:{_esc(summary)}",
            # kein Location-Feld vorhanden -> ggf. später ergänzen
            "STATUS:CONFIRMED",
            "END:VEVENT",
        ])

    lines.append("END:VCALENDAR")
    ics = "\r\n".join(lines)

    # Caching/Validation
    etag = hashlib.sha256(ics.encode("utf-8")).hexdigest()
    latest_update = max([getattr(g, "updated", now) for g in g_qs] + [now])

    resp = HttpResponse(ics, content_type="text/calendar; charset=utf-8")
    resp["Content-Disposition"] = 'inline; filename="game_calendar.ics"'
    resp["Cache-Control"] = "max-age=300, public"
    resp["ETag"] = etag
    resp["Last-Modified"] = latest_update.astimezone(timezone.utc).strftime(
        "%a, %d %b %Y %H:%M:%S GMT"
    )
    return resp

def calendar_player_trainings(request, player_id: int):
    """
    Trainings-Kalender für EINEN Spieler:
    - Nur Trainings, die dieser Spieler besucht hat (attended=True)
    - Optional filterbar per club (UUID/int): ?club=<id>
    - Pflicht: season (UUID/int): ?season=<id>
    URL: /calendar/player/<player_id>/trainings.ics?season=...&club=...
    """
    season_id = request.GET.get("season")
    if not season_id:
        raise Http404("season query param required")
    club_id = request.GET.get("club")  # optional

    now = timezone.now()

    # Hole Attendance-Einträge des Spielers (besucht), in der Zukunft
    qs = Attendance.objects.select_related("training", "player").filter(
        player_id=player_id,
        season_id=season_id,
        attended=True,
        training__date__gte=now,
    )
    if club_id:
        qs = qs.filter(training__club_id=club_id)

    # Wenn nichts gefunden, trotzdem sinnvollen Kalender liefern
    attendances = list(qs.order_by("training__date"))

    # Player-Objekt (für Namen im Cal-Header)
    player = attendances[0].player if attendances else None
    player_name = getattr(player, "name", None) or str(player_id)

    # ICS-Header
    lines = [
        "BEGIN:VCALENDAR",
        "PRODID:-//Waatea//Player Training Calendar//EN",
        "VERSION:2.0",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        f"X-WR-CALNAME:Trainings – { _esc(player_name) }",
        f"X-WR-CALDESC: Trainings of { _esc(player_name) }",
        "X-WR-TIMEZONE:Europe/Zurich",
    ]

    nowstamp = _to_ics_utc(now)
    TRAINING_DURATION_MIN = 105  # nach Bedarf anpassen

    # Events hinzufügen (ein Event je Training)
    # Falls es theoretisch doppelte Attendance-Einträge gäbe, pro Training deduplizieren:
    seen_training_ids = set()

    for a in attendances:
        t = a.training
        if not t or t.id in seen_training_ids:
            continue
        seen_training_ids.add(t.id)

        uid = f"training-{t.id}@waatea.app"  # stabile UID (UUID des Trainings)
        dtstart = _to_ics_utc(t.date)
        dtend = _to_ics_utc(t.date + timedelta(minutes=TRAINING_DURATION_MIN))

        # Falls du in Training ein 'updated' Feld ergänzt hast, nutze es:
        lastmod_dt = getattr(t, "updated", None) or now
        lastmod = _to_ics_utc(lastmod_dt)

        desc_parts = []
        if t.remarks and t.remarks != "[]":
            desc_parts.append(str(t.remarks))
        if t.review and t.review != "[]":
            desc_parts.append(str(t.review))
        description = "\\n".join(desc_parts) if desc_parts else None

        lines.extend([
            "BEGIN:VEVENT",
            f"UID:{uid}",
            f"DTSTAMP:{nowstamp}",
            f"LAST-MODIFIED:{lastmod}",
            "SEQUENCE:0",
            f"DTSTART:{dtstart}",
            f"DTEND:{dtend}",
            "SUMMARY:Training",
            f"DESCRIPTION:{_esc(description)}" if description else "DESCRIPTION:",
            "STATUS:CONFIRMED",
            "END:VEVENT",
        ])

    lines.append("END:VCALENDAR")
    ics = "\r\n".join(lines)

    # Download-/Anzeigename
    filename_parts = ["trainings", str(player_name)]
    if club_id:
        filename_parts.append(f"club-{club_id}")
    filename = "_".join(filename_parts).replace(" ", "-") + ".ics"

    # Caching/Validierung
    etag = hashlib.sha256(ics.encode("utf-8")).hexdigest()
    latest_update = max(
        [getattr(a.training, "updated", now) for a in attendances] + [now]
    )

    resp = HttpResponse(ics, content_type="text/calendar; charset=utf-8")
    resp["Cache-Control"] = "max-age=300, public"
    resp["ETag"] = etag
    resp["Last-Modified"] = latest_update.astimezone(timezone.utc).strftime(
        "%a, %d %b %Y %H:%M:%S GMT"
    )
    resp['Content-Disposition'] = f'inline; filename="{filename}"'
    return resp


class Game(viewsets.ModelViewSet):
    queryset = GameModel.objects.all()
    serializer_class = GameSerializer

class ClubViewSet(viewsets.ModelViewSet):
    queryset = Club.objects.all()
    serializer_class = ClubSerializer

    # Set the default permission_classes to require authentication for standard actions
    permission_classes = [IsAuthenticated]
    authentication_classes = [SessionAuthentication, BasicAuthentication]

    # Override the get_permissions method to allow access without authentication for the custom action
    def get_permissions(self):
        if self.action == 'allclubs':
            self.permission_classes = [AllowAny]
        return super(ClubViewSet, self).get_permissions()

    @action(detail=False, methods=['get'])
    def allclubs(self, request):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

class User(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class Availability(viewsets.ModelViewSet):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer



