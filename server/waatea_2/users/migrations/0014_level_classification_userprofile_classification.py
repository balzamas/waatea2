# Generated by Django 4.1.8 on 2023-09-04 14:50

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ("waateaapp", "0010_links_historicalgame"),
        ("users", "0013_alter_userprofile_sportlomo_id"),
    ]

    operations = [
        migrations.CreateModel(
            name="Level",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=200)),
                ("icon", models.CharField(max_length=200)),
                ("created", models.DateTimeField(auto_now_add=True)),
                ("updated", models.DateTimeField(auto_now=True)),
                ("club", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to="waateaapp.club")),
            ],
        ),
        migrations.CreateModel(
            name="Classification",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=200)),
                ("icon", models.CharField(max_length=200)),
                ("created", models.DateTimeField(auto_now_add=True)),
                ("updated", models.DateTimeField(auto_now=True)),
                ("club", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to="waateaapp.club")),
            ],
        ),
        migrations.AddField(
            model_name="userprofile",
            name="classification",
            field=models.ForeignKey(
                blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to="users.classification"
            ),
        ),
    ]
