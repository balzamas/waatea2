# Generated by Django 4.1.8 on 2024-02-06 19:05

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ("waateaapp", "0015_alter_availability_unique_together"),
        ("users", "0019_abonnement_short"),
    ]

    operations = [
        migrations.AddField(
            model_name="position",
            name="club",
            field=models.ForeignKey(
                blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to="waateaapp.club"
            ),
        ),
    ]
