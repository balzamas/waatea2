# Generated by Django 4.1.8 on 2024-01-24 10:24

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0018_position_userprofile_positions"),
    ]

    operations = [
        migrations.AddField(
            model_name="abonnement",
            name="short",
            field=models.CharField(default="", max_length=200),
            preserve_default=False,
        ),
    ]