from django.contrib import admin
from .models import Club, Game, Team, Season, Availability

admin.site.register(Club)
admin.site.register(Game)
admin.site.register(Team)
admin.site.register(Season)
admin.site.register(Availability)
