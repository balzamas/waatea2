from django.contrib import admin
from .models import Club, Game, Team, Season, Availability, Training, Attendance, CurrentSeason, HistoricalGame, Links, \
    TrainingPart, LineUpPos
from waatea_2.users.models import UserProfile, Assessment, Abonnement, Classification

admin.site.register(Club)
admin.site.register(Team)
admin.site.register(Season)
admin.site.register(CurrentSeason)
admin.site.register(Links)
admin.site.register(Classification)
admin.site.register(Assessment)
admin.site.register(Abonnement)
admin.site.register(TrainingPart)

@admin.register(LineUpPos)
class LineUpPosAdmin(admin.ModelAdmin):
    list_display = ["player", "position", "game"]
    ordering = ["game__date"]
@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ["player", "training", "attended", "season"]
    list_filter = ["training__date", "player__name", "season__name"]
    ordering = ["training__date"]

@admin.register(Availability)
class AvailabilityAdmin(admin.ModelAdmin):
    list_display = ["player", "season", "state", "dayofyear"]
    list_filter = ["season__name"]
    ordering = ["season"]


@admin.register(Training)
class TrainingAdmin(admin.ModelAdmin):
    list_display = ["date", "season", "club"]
    list_filter = ["season__name", "date"]
    ordering = ["-date"]
@admin.register(Game)
class GameAdmin(admin.ModelAdmin):
    list_display = ["home", "away", "date", "season", "club"]
    list_filter = ["season__name", "date"]
    ordering = ['date']


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "assessment", "permission", "is_playing"]
    ordering = ['user']

@admin.register(HistoricalGame)
class HistoricalGameAdmin(admin.ModelAdmin):
    list_display = ["played_for", "played_against", "player", "date", "position", "competition"]
    ordering = ['player__name']
