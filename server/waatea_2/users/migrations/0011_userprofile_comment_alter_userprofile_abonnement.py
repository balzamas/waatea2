# Generated by Django 4.1.8 on 2023-08-26 14:07

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0010_userprofile_abonnement"),
    ]

    operations = [
        migrations.AddField(
            model_name="userprofile",
            name="comment",
            field=models.TextField(default="[]"),
        ),
        migrations.AlterField(
            model_name="userprofile",
            name="abonnement",
            field=models.IntegerField(choices=[(0, "Not Set"), (1, "None"), (2, "Half fare"), (3, "GA")], default=0),
        ),
    ]
