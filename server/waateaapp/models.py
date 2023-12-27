from django.db import models
import uuid
from waatea_2.users.models import User
from waateaapp.model_club import Club

def upload_to(instance, filename):
    return 'images/{filename}'.format(filename=filename)

class Season(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    start = models.DateTimeField()

    def __str__(self):
        return self.name

class Training(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateTimeField()
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    season = models.ForeignKey(Season, on_delete=models.CASCADE)
    dayofyear = models.IntegerField(default=-1)
    remarks = models.TextField(default="[]")
    review = models.TextField(default="[]")

    def __str__(self):
        return self.date.__str__()
    def save(self, *args, **kwargs):
        self.dayofyear = self.date.timetuple().tm_yday
        super(Training, self).save(*args, **kwargs)

class TrainingPart(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    training = models.ForeignKey(Training, on_delete=models.CASCADE)
    description = models.TextField(default="")
    order = models.PositiveIntegerField()
    minutes = models.PositiveIntegerField(default=1)


class Team(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    is_from_club = models.BooleanField()

    def __str__(self):
        return self.name


class Attendance(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    player = models.ForeignKey(User, on_delete=models.CASCADE)
    training = models.ForeignKey(Training, on_delete=models.CASCADE, related_name='attendances')
    attended = models.BooleanField()
    season = models.ForeignKey(Season, on_delete=models.CASCADE)
    dayofyear = models.IntegerField(default=-1)

    def __str__(self):
        return self.dayofyear.__str__() + " " + self.player.name + " " + str(self.attended)
class Game(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    home = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='home_games')
    away = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='away_games')
    season = models.ForeignKey(Season, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    date = models.DateTimeField()
    dayofyear = models.IntegerField(default=-1)
    lineup_published = models.BooleanField(default=False)


    def __str__(self):
        return self.home.name + " - " + self.away.name

    def save(self, *args, **kwargs):
        self.dayofyear = self.date.timetuple().tm_yday
        super(Game, self).save(*args, **kwargs)

class Availability(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    player = models.ForeignKey(User, on_delete=models.CASCADE)
    state = models.IntegerField() #1 = Not available 2= Maybe 3=Available
    season = models.ForeignKey(Season, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    dayofyear = models.IntegerField(default=-1)

    def __str__(self):
        return self.dayofyear.__str__() + " " + self.player.name

    class Meta:
       unique_together = ("player", "season", "dayofyear")

class CurrentSeason(models.Model):
    season = models.ForeignKey(Season, on_delete=models.CASCADE)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.club.name

class Links(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    url = models.CharField(max_length=200)
    icon = models.CharField(max_length=200)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class HistoricalGame(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    played_for = models.CharField(max_length=200)
    played_against = models.CharField(max_length=200)
    player = models.ForeignKey(User, on_delete=models.CASCADE)
    date = models.DateTimeField()
    position = models.CharField(max_length=200)
    competition = models.CharField(max_length=200)

    class Meta:
       unique_together = ("played_for", "played_against", "date", "player")

class LineUpPos(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    player = models.ForeignKey(User, on_delete=models.CASCADE, blank=True, null=True)
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    position = models.IntegerField() #1 = Not available 2= Maybe 3=Available
    remarks = models.TextField(default="")

    class Meta:
       unique_together = ("game", "position")
