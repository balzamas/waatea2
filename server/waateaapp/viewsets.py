from datetime import datetime, timedelta

from rest_framework import viewsets, generics
from rest_framework.generics import UpdateAPIView, CreateAPIView
from rest_framework.decorators import api_view
from waatea_2.users.models import UserProfile
from .models import Game, User, Availability, Attendance, Training, CurrentSeason, HistoricalGame
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer, AttendanceSerializer, \
    TrainingSerializer, CurrentSeasonSerializer, TrainingAttendanceCountSerializer, TrainingAttendanceSerializer, \
    UserProfileSerializer, GameAvailCountSerializer, HistoricalGameSerializer
from rest_framework.permissions import IsAuthenticated
from django.utils.timezone import make_aware
from rest_framework.response import Response
from rest_framework import status

class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    ordering_fields = ['date']
    ordering = ['date']

class HistoricalGameFilterAPIView(generics.ListAPIView):
    queryset = HistoricalGame.objects.order_by('-date')
    serializer_class = HistoricalGameSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        player = self.request.query_params.get('player')

        if player:
            queryset = queryset.filter(player=player)

        return queryset
class GameCurrentFilterAPIView(generics.ListAPIView):
    queryset = Game.objects.filter(date__gte=make_aware(datetime.today())).order_by('date')
    serializer_class = GameSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')
        season = self.request.query_params.get('season')

        if club:
            queryset = queryset.filter(club=club)
        if club and season:
            queryset = queryset.filter(club=club, season=season)


        return queryset

class GameCurrentAvailCountFilterAPIView(generics.ListAPIView):
    queryset = Game.objects.filter(date__gte=make_aware(datetime.today())).order_by('date')
    serializer_class = GameAvailCountSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')
        season = self.request.query_params.get('season')

        if club:
            queryset = queryset.filter(club=club)
        if club and season:
            queryset = queryset.filter(club=club, season=season)

        return queryset

class TrainingFilterAPIView(generics.ListAPIView):
    queryset = Training.objects.order_by('date')
    serializer_class = TrainingSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')
        season = self.request.query_params.get('season')

        if club and season:
            queryset = queryset.filter(club=club, season=season)

        return queryset

class TrainingCurrentFilterAPIView(generics.ListAPIView):
    queryset = Training.objects.filter(date__gte=(make_aware(datetime.now())-timedelta(hours=23))).filter(date__lte=(make_aware(datetime.now())+timedelta(hours=23))).order_by('date')
    serializer_class = TrainingSerializer
    ordering = ['date']

    def get_queryset(self):
        print(datetime.now())
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')
        season = self.request.query_params.get('season')

        if club and season:
            queryset = queryset.filter(club=club, season=season)

        return queryset


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserFilterAPIView(generics.ListAPIView):
    queryset = User.objects.all().order_by('name')
    serializer_class = UserSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        email = self.request.query_params.get('email')
        club = self.request.query_params.get('club')
        is_playing = self.request.query_params.get('is_playing')

        if email:
            queryset = queryset.filter(email=email)
        elif is_playing and club:
            queryset = queryset.filter(userprofile__is_playing=is_playing)
        elif club:
            queryset = queryset.filter(club=club)

        return queryset

class UserDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserProfileDetail(generics.RetrieveUpdateAPIView):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
          return UserProfile.objects.get(user_id=self.kwargs['pk'])

class AvailabilityViewSet(viewsets.ModelViewSet):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer

class AvailiabilityFilterAPIView(generics.ListAPIView):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        player = self.request.query_params.get('player')
        dayofyear = self.request.query_params.get('dayofyear')
        season = self.request.query_params.get('season')

        if dayofyear and player and season:
            queryset = queryset.filter(dayofyear=dayofyear, player=player, season=season)
        elif player and season:
            queryset = queryset.filter(player=player, season=season)
        elif dayofyear and season:
            print("Right path")
            queryset = queryset.filter(dayofyear=dayofyear, season=season, player__userprofile__is_playing=True)

        return queryset

class AvailabilityUpdateAPIView(UpdateAPIView):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer

class AvailabilityCreateAPIView(CreateAPIView):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer

class AttendanceFilterAPIView(generics.ListAPIView):
    queryset = Attendance.objects.all()
    serializer_class = AttendanceSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        player = self.request.query_params.get('player')
        training = self.request.query_params.get('training')
        season = self.request.query_params.get('season')

        if training and player and season:
            queryset = queryset.filter(training=training, player=player, season=season)
        elif player and season:
            queryset = queryset.filter(player=player, season=season)
        elif training and season:
            queryset = queryset.filter(training=training, season=season)
        elif training and player:
            queryset = queryset.filter(training=training, player=player)

        return queryset
class AttendanceUpdateAPIView(UpdateAPIView):
    queryset = Attendance.objects.all()
    serializer_class = AttendanceSerializer

class AttendanceCreateAPIView(CreateAPIView):
    queryset = Attendance.objects.all()
    serializer_class = AttendanceSerializer

class TrainingCreateAPIView(CreateAPIView):
    queryset = Training.objects.all()
    serializer_class = TrainingSerializer

class CurrentSeasonFilterAPIView(generics.ListAPIView):
    queryset = CurrentSeason.objects.all()
    serializer_class = CurrentSeasonSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset

class TrainingAttendanceCountAPIView(generics.ListAPIView):
    queryset = Training.objects.order_by('-date')
    serializer_class = TrainingAttendanceCountSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        season = self.request.query_params.get('season')
        club = self.request.query_params.get('club')

        if season and club:
            queryset = queryset.filter(season=season, club=club)
        elif season:
            queryset = queryset.filter(season=season)

        return queryset

class TrainingAttendanceViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = TrainingAttendanceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.request.query_params.get('user_id')
        season_id = self.request.query_params.get('season')
        club_id = self.request.query_params.get('club')
        last_n = int(self.request.query_params.get('last_n', 0))  # Number of last trainings

        queryset = Training.objects.filter(
            club_id=club_id,
            season_id=season_id,
            date__lte=datetime.now(),  # Only past trainings
        ).distinct()

        if last_n > 0:
            queryset = queryset.order_by('-date')[:last_n]

        return queryset

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['user_id'] = self.request.query_params.get('user_id')
        return context

@api_view(['POST'])
def change_password(request):
    user = request.user
    new_password = request.data.get('new_password')

    if not new_password:
        return Response({'error': 'New password is required.'}, status=status.HTTP_400_BAD_REQUEST)

    user.set_password(new_password)
    user.save()

    return Response({'message': 'Password changed successfully.'}, status=status.HTTP_200_OK)
