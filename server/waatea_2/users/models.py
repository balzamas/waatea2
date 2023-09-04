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

class Level(models.Model):
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

class UserProfile(models.Model):
    LEVEL_CHOICES = [
        (0, 'High performance, performance motivation'),
        (1, 'Basic performance, performance motivation'),
        (2, 'High performance, time deficit'),
        (3, 'High performance, social motivation'),
        (4, 'Basic performance, social motivation'),
        (5, 'Newcomer'),
    ]

    PERMISSION_CHOICES = [
        (0, 'Player'),
        (1, 'Coach'),
        (2, 'Admin'),
    ]

    ABONNEMENT_CHOICES = [
        (0, 'Not Set'),
        (1, 'None'),
        (2, 'Half fare'),
        (3, 'GA'),

    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    level = models.IntegerField(choices=LEVEL_CHOICES, default=5)
    permission = models.IntegerField(choices=PERMISSION_CHOICES, default=0)
    abonnement = models.IntegerField(choices=ABONNEMENT_CHOICES, default=0)
    comment = models.TextField(default="[]")
    is_playing = models.BooleanField(default=True)
    sportlomo_id = models.CharField(max_length=200, blank=True)
    classification = models.ForeignKey(Classification, on_delete=models.SET_NULL, blank=True, null=True)
    mobile_phone = CharField(_("Mobile phone number (format: 41798257004)"), blank=True, max_length=255)

    def __str__(self):
        return f"{self.user.name}"
