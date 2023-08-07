# Generated by Django 4.1.8 on 2023-07-31 12:37

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("waateaapp", "0005_availability_season_currentseason"),
    ]

    operations = [
        migrations.RenameField(
            model_name="attendance",
            old_name="state",
            new_name="attended",
        ),
        migrations.RemoveField(
            model_name="attendance",
            name="training",
        ),
        migrations.AddField(
            model_name="attendance",
            name="dayofyear",
            field=models.IntegerField(default=-1),
        ),
        migrations.AddField(
            model_name="training",
            name="dayofyear",
            field=models.IntegerField(default=-1),
        ),
    ]