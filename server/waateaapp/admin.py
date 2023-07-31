from django.contrib import admin
from .models import Club, Game, Team, Season, Availability, Training, Attendance

admin.site.register(Club)
admin.site.register(Game)
admin.site.register(Team)
admin.site.register(Season)
admin.site.register(Availability)
admin.site.register(Training)
admin.site.register(Attendance)
