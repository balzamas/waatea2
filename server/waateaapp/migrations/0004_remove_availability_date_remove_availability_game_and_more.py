# Generated by Django 4.1.8 on 2023-07-28 20:26

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("waateaapp", "0003_availability_dayofyear"),
    ]

    operations = [
        migrations.RemoveField(
            model_name="availability",
            name="date",
        ),
        migrations.RemoveField(
            model_name="availability",
            name="game",
        ),
        migrations.AddField(
            model_name="game",
            name="dayofyear",
            field=models.IntegerField(default=-1),
        ),
    ]
