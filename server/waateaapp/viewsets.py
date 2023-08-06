from datetime import datetime, timedelta

from rest_framework import viewsets, generics
from rest_framework.generics import UpdateAPIView, CreateAPIView
from .models import Game, User, Availability, Attendance, Training, CurrentSeason
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer, AttendanceSerializer, TrainingSerializer, CurrentSeasonSerializer

class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    ordering_fields = ['date']
    ordering = ['date']

class GameCurrentFilterAPIView(generics.ListAPIView):
    queryset = Game.objects.filter(date__gte=datetime.today()).order_by('date')
    serializer_class = GameSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

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
    queryset = Training.objects.filter(date__gte=(datetime.today()-timedelta(hours=23))).filter(date__lte=(datetime.today()+timedelta(hours=23))).order_by('date')
    serializer_class = TrainingSerializer
    ordering = ['date']

    def get_queryset(self):
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

        if email:
            queryset = queryset.filter(email=email)
        elif club:
            queryset = queryset.filter(club=club)

        return queryset


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
            queryset = queryset.filter(dayofyear=dayofyear, season=season)

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
        dayofyear = self.request.query_params.get('dayofyear')
        season = self.request.query_params.get('season')

        if dayofyear and player and season:
            queryset = queryset.filter(dayofyear=dayofyear, player=player, season=season)
        elif player and season:
            queryset = queryset.filter(player=player, season=season)
        elif dayofyear and season:
            queryset = queryset.filter(dayofyear=dayofyear, season=season)

        return queryset
class AttendanceUpdateAPIView(UpdateAPIView):
    queryset = Attendance.objects.all()
    serializer_class = AttendanceSerializer

class AttendanceCreateAPIView(CreateAPIView):
    queryset = Attendance.objects.all()
    serializer_class = AttendanceSerializer

class CurrentSeasonFilterAPIView(generics.ListAPIView):
    queryset = CurrentSeason.objects.all()
    serializer_class = CurrentSeasonSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset
