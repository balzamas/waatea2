# Generated by Django 4.1.8 on 2023-08-24 14:46

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0009_userprofile_permission"),
    ]

    operations = [
        migrations.AddField(
            model_name="userprofile",
            name="abonnement",
            field=models.IntegerField(
                choices=[(0, "Not Set"), (1, "None"), (2, "Half fare"), (3, "Half fare")], default=0
            ),
        ),
    ]