# Generated by Django 4.1.8 on 2023-08-29 19:58

from django.conf import settings
from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("waateaapp", "0011_rename_away_historicalgame_played_against_and_more"),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name="historicalgame",
            unique_together={("played_for", "played_against", "date", "player")},
        ),
    ]
