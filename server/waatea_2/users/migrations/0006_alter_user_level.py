# Generated by Django 4.1.8 on 2023-07-28 19:20

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0005_user_level"),
    ]

    operations = [
        migrations.AlterField(
            model_name="user",
            name="level",
            field=models.IntegerField(
                choices=[
                    (0, "High performance, performance motivation"),
                    (1, "Basic performance, performance motivation"),
                    (2, "High performance, time deficit"),
                    (3, "High performance, social motivation"),
                    (4, "Basic performance, social motivation"),
                    (5, "Newcomer"),
                ],
                default=5,
            ),
        ),
    ]
