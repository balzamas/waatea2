from django.contrib.auth.models import AbstractUser
from django.db.models import CharField, EmailField
from django.urls import reverse
from django.utils.translation import gettext_lazy as _
from django.db import models

import waateaapp
from waatea_2.users.managers import UserManager
from waateaapp.model_club import Club


class User(AbstractUser):
    """
    Default custom user model for Waatea 2.
    If adding fields that need to be filled at user signup,
    check forms.SignupForm and forms.SocialSignupForms accordingly.
    """
    LEVEL_CHOICES=[
        (0, 'High performance, performance motivation'),
        (1, 'Basic performance, performance motivation'),
        (2, 'High performance, time deficit'),
        (3, 'High performance, social motivation'),
        (4, 'Basic performance, social motivation'),
        (5, 'Newcomer'),
    ]

    # First and last name do not cover name patterns around the globe
    name = CharField(_("Name of User"), blank=True, max_length=255)
    email = EmailField(_("email address"), unique=True)
    username = None  # type: ignore
    mobile_phone = CharField(_("Mobile phone number (format: 41798257004)"), blank=True, max_length=255)
    club = models.ForeignKey(Club, on_delete=models.CASCADE, blank=True, null=True)
    level = models.IntegerField(choices=LEVEL_CHOICES,default=5)


    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    def get_absolute_url(self) -> str:
        """Get URL for user's detail view.

        Returns:
            str: URL for user detail.

        """
        return reverse("users:detail", kwargs={"pk": self.id})
