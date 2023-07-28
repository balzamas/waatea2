from django.db import models
import uuid
from waatea_2.users.models import User
from waateaapp.model_club import Club


class Season(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    start = models.DateTimeField()

    def __str__(self):
        return self.name

class Team(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    is_from_club = models.BooleanField()

    def __str__(self):
        return self.name

class Training(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateTimeField()
    club = models.ForeignKey(Club, on_delete=models.CASCADE)

class Attendance(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    player = models.ForeignKey(User, on_delete=models.CASCADE)
    state = models.BooleanField()
    training = models.ForeignKey(Training, on_delete=models.CASCADE)

class Game(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    home = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='home_games')
    away = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='away_games')
    season = models.ForeignKey(Season, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    date = models.DateTimeField()

    def __str__(self):
        return self.home.name + " - " + self.away.name

class Availability(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    player = models.ForeignKey(User, on_delete=models.CASCADE)
    date = models.DateTimeField()
    state = models.IntegerField()
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)

    def __str__(self):
        return self.game.__str__() + " " + self.game.date.strftime("%m/%d/%Y")
