from django.contrib.auth.models import AbstractUser
from django.db.models import CharField, EmailField
from django.urls import reverse
from django.utils.translation import gettext_lazy as _
from django.db import models
from django.db.models import JSONField

import waateaapp
from waatea_2.users.managers import UserManager
from waateaapp.model_club import Club


class User(AbstractUser):
    """
    Default custom user model for Waatea 2.
    If adding fields that need to be filled at user signup,
    check forms.SignupForm and forms.SocialSignupForms accordingly.
    """
    # First and last name do not cover name patterns around the globe
    name = CharField(_("Name of User"), blank=True, max_length=255)
    email = EmailField(_("email address"), unique=True)
    username = None  # type: ignore
    club = models.ForeignKey(Club, on_delete=models.CASCADE, blank=True, null=True)


    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    def get_absolute_url(self) -> str:
        """Get URL for user's detail view.

        Returns:
            str: URL for user detail.

        """
        return reverse("users:detail", kwargs={"pk": self.id})
    def __str__(self):
        return f"{self.name} - {self.email}"

class Position(models.Model):
    position = models.CharField(max_length=10)
    club = models.ForeignKey(Club, on_delete=models.CASCADE,  blank=True, null=True)

    def __str__(self):
        return self.position

class Assessment(models.Model):
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    icon = models.CharField(max_length=200)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name + " / " + self.club.name

class Classification(models.Model):
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    icon = models.CharField(max_length=200)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name + " / " + self.club.name

class Abonnement(models.Model):
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    short = models.CharField(max_length=200)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name + " / " + self.club.name

class UserProfile(models.Model):


    PERMISSION_CHOICES = [
        (0, 'Player'),
        (1, 'Coach'),
        (2, 'Admin'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    permission = models.IntegerField(choices=PERMISSION_CHOICES, default=0)
    comment = models.TextField(default="[]")
    is_playing = models.BooleanField(default=True)
    sportlomo_id = models.CharField(max_length=200, blank=True)
    classification = models.ForeignKey(Classification, on_delete=models.SET_NULL, blank=True, null=True)
    abo = models.ForeignKey(Abonnement, on_delete=models.SET_NULL, blank=True, null=True)
    assessment = models.ForeignKey(Assessment, on_delete=models.SET_NULL, blank=True, null=True)
    positions = models.ManyToManyField(Position, blank=True)
    mobile_phone = CharField(_("Mobile phone number (format: 41798257004)"), blank=True, max_length=255)

    def __str__(self):
        return f"{self.user.name}"
