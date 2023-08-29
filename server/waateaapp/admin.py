from django.contrib import admin
from .models import Club, Game, Team, Season, Availability, Training, Attendance, CurrentSeason, HistoricalGame
from waatea_2.users.models import UserProfile

admin.site.register(Club)
admin.site.register(Team)
admin.site.register(Season)
admin.site.register(Availability)
admin.site.register(Attendance)
admin.site.register(CurrentSeason)

@admin.register(Training)
class TrainingAdmin(admin.ModelAdmin):
    list_display = ["date", "season", "club"]
    list_filter = ["season"]
    ordering = ["-date"]
@admin.register(Game)
class GameAdmin(admin.ModelAdmin):
    list_display = ["home", "away", "date", "season", "club"]
    ordering = ['date']


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "level", "permission", "is_playing"]
    ordering = ['user']

@admin.register(HistoricalGame)
class HistoricalGameAdmin(admin.ModelAdmin):
    list_display = ["played_for", "played_against", "player", "date", "position", "competition"]
    ordering = ['player__name']

