from django.contrib import admin, messages
from django.contrib.auth import admin as auth_admin
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
import os
from django.shortcuts import redirect
from django.urls import path, reverse
from integrations.helfereinsatz import sync_club_hours_from_helpers
from .models import ClubHoursSync
from django.conf import settings

from waatea_2.users.forms import UserAdminChangeForm, UserAdminCreationForm

User = get_user_model()


@admin.register(User)
class UserAdmin(auth_admin.UserAdmin):
    form = UserAdminChangeForm
    add_form = UserAdminCreationForm
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        (_("Personal info"), {"fields": ("name",)}),
        (
            _("Permissions"),
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",

                    "club"
                ),
            },
        ),
        (_("Important dates"), {"fields": ("last_login", "date_joined")}),
    )
    list_display = ["name", "email", "is_superuser"]
    search_fields = ["name"]
    ordering = ["name"]
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "password1", "password2"),
            },
        ),
    )

@admin.register(ClubHoursSync)
class ClubHoursSyncAdmin(admin.ModelAdmin):
    change_list_template = "admin/clubhours_sync_changelist.html"

    # Keine CRUD-Rechte nötig
    def has_add_permission(self, request): return False
    def has_change_permission(self, request, obj=None): return False
    def has_delete_permission(self, request, obj=None): return False

    def get_urls(self):
        urls = super().get_urls()
        app_label = self.model._meta.app_label
        model_name = self.model._meta.model_name
        custom = [
            path(
                "run/",
                self.admin_site.admin_view(self.run_sync),
                name=f"{app_label}_{model_name}_run",
            ),
        ]
        return custom + urls

    def changelist_view(self, request, extra_context=None):
        extra_context = extra_context or {}
        run_url = reverse(f"admin:{self.model._meta.app_label}_{self.model._meta.model_name}_run")
        extra_context["run_sync_url"] = run_url
        return super().changelist_view(request, extra_context=extra_context)

    def run_sync(self, request):
        # Nur per POST ausführen (CSRF-geschützt)
        if request.method != "POST":
            return redirect(f"admin:{self.model._meta.app_label}_{self.model._meta.model_name}_changelist")


        api_key = settings.HELFEREINSATZ_API_KEY
        slug = settings.HELFEREINSATZ_SLUG
        base = settings.HELFEREINSATZ_BASE
        userprofile_app = os.getenv("USERPROFILE_APP") or self.model._meta.app_label  # Default: gleiche App

        if not api_key:
            messages.error(request, "HELFEREINSATZ_API_KEY fehlt (.env).")
            return redirect(f"admin:{self.model._meta.app_label}_{self.model._meta.model_name}_changelist")

        try:
            res = sync_club_hours_from_helpers(
                api_key=api_key,
                slug=slug,
                base_url=base,

            )
            messages.success(request, f"Sync completed: {res}")
        except Exception as e:
            messages.error(request, f"Sync failed: {e}")

        return redirect(f"admin:{self.model._meta.app_label}_{self.model._meta.model_name}_changelist")
