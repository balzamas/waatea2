from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views import defaults as default_views
from django.views.decorators.csrf import csrf_exempt
from django.views.generic import TemplateView
from waateaapp import views
from rest_framework import routers
from rest_framework.authtoken import views as restviews
from waateaapp.viewsets import GameCurrentFilterAPIView, UserFilterAPIView, AvailiabilityFilterAPIView, AvailabilityUpdateAPIView, AvailabilityCreateAPIView
router = routers.DefaultRouter(trailing_slash=False)
router.register('gamedetails', views.Game)
router.register('userdetails', views.User)
router.register('availabilitydetails', views.Availability)



urlpatterns = [
    path("", TemplateView.as_view(template_name="pages/home.html"), name="home"),
    path("about/", TemplateView.as_view(template_name="pages/about.html"), name="about"),
    # Django Admin, use {% url 'admin:index' %}
    path(settings.ADMIN_URL, admin.site.urls),
    # User management
    path("users/", include("waatea_2.users.urls", namespace="users")),
    path("accounts/", include("allauth.urls")),
    path('api/', include(router.urls)),
    path('api-token-auth/', restviews.obtain_auth_token, name='api-token-auth'),
    # Your stuff: custom urls includes go here
    path('api/games_current/filter/', GameCurrentFilterAPIView.as_view(), name='game-filter'),
    path('api/users/filter/', UserFilterAPIView.as_view(), name='user-filter'),
    path('api/availabilities/filter/', AvailiabilityFilterAPIView.as_view(), name='availability-filter'),

    path('api/availability/<uuid:pk>/', AvailabilityUpdateAPIView.as_view(), name='availability-update'),
    path('api/availability/', AvailabilityCreateAPIView.as_view(), name='availability-create'),

              ] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)


if settings.DEBUG:
    # This allows the error pages to be debugged during development, just visit
    # these url in browser to see how these error pages look like.
    urlpatterns += [
        path(
            "400/",
            default_views.bad_request,
            kwargs={"exception": Exception("Bad Request!")},
        ),
        path(
            "403/",
            default_views.permission_denied,
            kwargs={"exception": Exception("Permission Denied")},
        ),
        path(
            "404/",
            default_views.page_not_found,
            kwargs={"exception": Exception("Page not Found")},
        ),
        path("500/", default_views.server_error),
    ]
    if "debug_toolbar" in settings.INSTALLED_APPS:
        import debug_toolbar

        urlpatterns = [path("__debug__/", include(debug_toolbar.urls))] + urlpatterns
