from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views import defaults as default_views
from django.views.decorators.csrf import csrf_exempt
from django.views.generic import TemplateView
from waateaapp import views, viewsets
from rest_framework import routers
from rest_framework.authtoken import views as restviews
from waateaapp.viewsets import GameCurrentFilterAPIView, UserFilterAPIView, AvailiabilityFilterAPIView, \
    AvailabilityUpdateAPIView, AvailabilityCreateAPIView, AttendanceCreateAPIView, AttendanceFilterAPIView, \
    AttendanceUpdateAPIView, TrainingFilterAPIView, TrainingCurrentFilterAPIView, CurrentSeasonFilterAPIView, \
    TrainingAttendanceCountAPIView, TrainingAttendanceViewSet, TrainingCreateAPIView, UserProfileDetail, \
    UserDetailAPIView, GameCurrentAvailCountFilterAPIView, change_password, HistoricalGameFilterAPIView, \
    LinksFilterAPIView, ClassificationFilterAPIView, AssessmentFilterAPIView, AbonnementFilterAPIView, get_csrf_token, \
    TrainingPartCreateAPIView, TrainingPartUpdateAPIView, LineUpPosCreateAPIView, LineUpPosUpdateAPIView, \
    GameUpdateAPIView, GamePastFilterAPIView, TrainingDeleteAPIView, TeamsAPIView, GameCreateAPIView, AttendingUsersViewSet, PositionFilterAPIView
from django.views.static import serve
import os
from waatea_2.users.views import register_user
router = routers.DefaultRouter(trailing_slash=False)
router.register('clubs', views.ClubViewSet)
router.register('gamedetails', views.Game)
router.register('userdetails', views.User)
router.register('availabilitydetails', views.Availability)
router.register('training-attendance', TrainingAttendanceViewSet, basename='training-attendance')

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLUTTER_WEB_APP = os.path.join(BASE_DIR, 'client')

def flutter_redirect(request, resource):
    return serve(request, resource, FLUTTER_WEB_APP)

urlpatterns = [
      path('api/register/', register_user, name='register'),
      path('client/', lambda r: flutter_redirect(r, 'index.html')),
      path('client/<path:resource>', flutter_redirect),
    path("", TemplateView.as_view(template_name="pages/home.html"), name="home"),
    path("about/", TemplateView.as_view(template_name="pages/about.html"), name="about"),

    path('get-csrf-token/', get_csrf_token, name='get-csrf-token'),
    # Django Admin, use {% url 'admin:index' %}
    path(settings.ADMIN_URL, admin.site.urls),
    # User management
    path("users/", include("waatea_2.users.urls", namespace="users")),
    path('api/user-profile/<str:email>/', UserProfileDetail.as_view(), name='user-profile-detail'),
    path("accounts/", include("allauth.urls")),
    path('api/', include(router.urls)),
    path('api-token-auth/', restviews.obtain_auth_token, name='api-token-auth'),
    # Your stuff: custom urls includes go here
    path('api/games_current/filter/', GameCurrentFilterAPIView.as_view(), name='game-filter'),
    path('api/games_past/filter/', GamePastFilterAPIView.as_view(), name='game-filter'),
    path('api/games_current_avail/filter/', GameCurrentAvailCountFilterAPIView.as_view(), name='game-avail-filter'),

    path('api/classifications/filter/', ClassificationFilterAPIView.as_view(), name='classification-filter'),
    path('api/assessments/filter/', AssessmentFilterAPIView.as_view(),
       name='assessments-filter'),
    path('api/abonnements/filter/', AbonnementFilterAPIView.as_view(),
       name='abonnement-filter'),
                  path('api/positions/filter/', PositionFilterAPIView.as_view(),
                       name='positions-filter'),

                  path('api/game/', GameCreateAPIView.as_view(), name='game-create'),

                  path('api/game/<uuid:pk>/', GameUpdateAPIView.as_view(), name='game-update'),

                  path('api/historical_games/filter/', HistoricalGameFilterAPIView.as_view(), name='historical-game-filter'),

    path('api/users/filter/', UserFilterAPIView.as_view(), name='user-filter'),
    path('api/availabilities/filter/', AvailiabilityFilterAPIView.as_view(), name='availability-filter'),
    path('api/availability/<uuid:pk>/', AvailabilityUpdateAPIView.as_view(), name='availability-update'),
    path('api/availability/', AvailabilityCreateAPIView.as_view(), name='availability-create'),

    path('api/trainings/filter/', TrainingFilterAPIView.as_view(), name='training-filter'),
    path('api/training_current/filter/', TrainingCurrentFilterAPIView.as_view(), name='training-current-filter'),
    path('api/training/', TrainingCreateAPIView.as_view(), name='training-create'),
    path('api/trainings/<uuid:pk>/', TrainingDeleteAPIView.as_view(), name='training-delete'),

    path('api/links/filter/', LinksFilterAPIView.as_view(), name='links-filter'),

    path('api/attendingusers/<uuid:uid>/', AttendingUsersViewSet.as_view({'get': 'list'}),
                       name='attending-users-list'),
    path('api/attendances/filter/', AttendanceFilterAPIView.as_view(), name='attendance-filter'),
    path('api/attendance/<uuid:pk>/', AttendanceUpdateAPIView.as_view(), name='attendance-update'),
    path('api/attendance/', AttendanceCreateAPIView.as_view(), name='attendance-create'),

    path('api/currentseason/filter/', CurrentSeasonFilterAPIView.as_view(), name='currentseason-filter'),

                  path('api/trainings/', TrainingAttendanceCountAPIView.as_view(), name='training-list'),

                  path('api/teams/', TeamsAPIView.as_view(), name='teams-list'),

    path('api/trainingparts/', viewsets.TrainingPartViewSet.as_view({'get': 'list'}), name='trainingpart-list'),
    path('api/trainingpart/', TrainingPartCreateAPIView.as_view(), name='trainingpart-create'),
                  path('api/trainingpart/<uuid:pk>/', TrainingPartUpdateAPIView.as_view(), name='trainingpart-update'),
path('api/trainingparts/<uuid:pk>/', viewsets.delete_training_part),

                  path('api/lineupposes/', viewsets.LineUpPosViewSet.as_view({'get': 'list'}),
                       name='lineuppos-list'),
                  path('api/lineuppos/', LineUpPosCreateAPIView.as_view(), name='lineuppos-create'),
                  path('api/lineuppos/<uuid:pk>/', LineUpPosUpdateAPIView.as_view(), name='lineuppos-update'),

                  path('rest-auth/', include('rest_framework.urls', namespace='rest_framework')),

    path('api/change-password/', change_password, name='change_password'),
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
