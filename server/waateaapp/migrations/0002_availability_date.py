# Generated by Django 4.1.8 on 2023-07-28 19:20

import datetime
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("waateaapp", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="availability",
            name="date",
            field=models.DateTimeField(default=datetime.datetime(2023, 7, 28, 21, 20, 59, 214252)),
            preserve_default=False,
        ),
    ]
