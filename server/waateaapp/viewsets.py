from datetime import datetime, timedelta, timezone

from rest_framework.decorators import action
from rest_framework import viewsets, generics, filters
from rest_framework.generics import UpdateAPIView, CreateAPIView
from rest_framework.decorators import api_view
from waatea_2.users.models import UserProfile, Classification, Abonnement, Assessment
from .models import Game, User, Availability, Attendance, Training, CurrentSeason, HistoricalGame, Links, TrainingPart, LineUpPos, Team
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer, AttendanceSerializer, \
    TrainingSerializer, CurrentSeasonSerializer, TrainingAttendanceCountSerializer, TrainingAttendanceSerializer, \
    UserProfileSerializer, GameAvailCountSerializer, HistoricalGameSerializer, LinksSerializer, AssessmentSerializer, \
    AbonnementSerializer, ClassificationSerializer, TrainingPartSerializer, LineUpPosSerializer, TeamSerializer, \
    GameCreateSerializer
from rest_framework.permissions import IsAuthenticated
from django.utils.timezone import make_aware
from rest_framework.response import Response
from rest_framework import status
from django.middleware import csrf
from django.http import JsonResponse
from django.db.models import Prefetch
from django.shortcuts import get_object_or_404
from django.core import serializers
from rest_framework.generics import DestroyAPIView

class TrainingPartViewSet(viewsets.ModelViewSet):
    serializer_class = TrainingPartSerializer

    def get_queryset(self):
        training_id = self.request.query_params.get('training')
        if training_id:
            return TrainingPart.objects.filter(training=training_id).order_by('order')
        return TrainingPart.objects.all().order_by('order')

class LineUpPosViewSet(viewsets.ModelViewSet):
    serializer_class = LineUpPosSerializer

    def get_queryset(self):
        game_id = self.request.query_params.get('game')
        if game_id:
            return LineUpPos.objects.filter(game=game_id).order_by('position')
        return LineUpPos.objects.all().order_by('position')

class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    ordering_fields = ['date']
    ordering = ['date']

class GameUpdateAPIView(generics.RetrieveUpdateAPIView):
    queryset = Game.objects.all()
    serializer_class = GameSerializer

    def perform_update(self, serializer):
        serializer.save()  # Use partial=True to allow partial updates
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
    queryset = Game.objects.filter(date__gte=datetime.now()).order_by('date')
    serializer_class = GameSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')
        season = self.request.query_params.get('season')
        dayofyear =  self.request.query_params.get('dayofyear')

        if club:
            queryset = queryset.filter(club=club)
        if club and season:
            queryset = queryset.filter(club=club, season=season)
        if club and season and dayofyear:
            queryset = queryset.filter(club=club, season=season, dayofyear=dayofyear)

        return queryset

class GamePastFilterAPIView(generics.ListAPIView):
    queryset = Game.objects.filter(date__lte=datetime.now()).order_by('-date')
    serializer_class = GameSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')
        season = self.request.query_params.get('season')
        dayofyear = self.request.query_params.get('dayofyear')

        if club:
            queryset = queryset.filter(club=club)
        if club and season:
            queryset = queryset.filter(club=club, season=season)
        if club and season and dayofyear:
            queryset = queryset.filter(club=club, season=season, dayofyear=dayofyear)

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

class LineUpPosFilterAPIView(generics.ListAPIView):
    queryset = LineUpPos.objects.order_by('game', 'position')
    serializer_class = LineUpPosSerializer
    ordering = ['position']

    def get_queryset(self):
        queryset = super().get_queryset()
        game = self.request.query_params.get('game')
        dayofyear = self.request.query_params.get('dayofyear')
        season = self.request.query_params.get('season')
        club = self.request.query_params.get('club')

        if game:
            queryset = queryset.filter(game=game)
        elif dayofyear and season and club:
            queryset = queryset.filter(game__dayofyear=dayofyear, season=season, club=club)


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

class LinksFilterAPIView(generics.ListAPIView):
    queryset = Links.objects.order_by('name')
    serializer_class = LinksSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset

class ClassificationFilterAPIView(generics.ListAPIView):
    queryset = Classification.objects.order_by('name')
    serializer_class = ClassificationSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset

class AssessmentFilterAPIView(generics.ListAPIView):
    queryset = Assessment.objects.order_by('name')
    serializer_class = AssessmentSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset

class AbonnementFilterAPIView(generics.ListAPIView):
    queryset = Abonnement.objects.order_by('name')
    serializer_class = AbonnementSerializer
    ordering = ['date']

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset

class TrainingCurrentFilterAPIView(generics.ListAPIView):
    serializer_class = TrainingSerializer
    ordering = ['date']

    def get_queryset(self):
        current_time = make_aware(datetime.now())
        print(current_time)
        queryset = Training.objects.filter(
            date__gte=current_time - timedelta(hours=23),
            date__lte=current_time + timedelta(hours=23)
        ).order_by('date')

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
        user_profile = UserProfile.objects.get(user__email=self.kwargs['email'])
        user_profile.positions.all()  # Retrieve positions for the user
        return user_profile

    def perform_update(self, serializer):
        # Include positions data in the update
        positions_data = self.request.data.get('positions')
        if positions_data is not None:
            serializer.save(positions=positions_data)
        else:
            serializer.save()

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

class AttendingUsersViewSet(viewsets.ViewSet):
    def list(self, request, uid=None):
        try:
            training = Training.objects.get(id=uid)
        except Training.DoesNotExist:
            return Response({'detail': 'Training not found'}, status=status.HTTP_404_NOT_FOUND)

        attendances = Attendance.objects.filter(training=training, attended=True).select_related('player')
        attending_users = [attendance.player for attendance in attendances]
        serializer = UserSerializer(attending_users, many=True)
        return Response(serializer.data)

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

class GameCreateAPIView(CreateAPIView):
    queryset = Game.objects.all()
    serializer_class = GameCreateSerializer
class TrainingCreateAPIView(CreateAPIView):
    queryset = Training.objects.all()
    serializer_class = TrainingSerializer

class TrainingDeleteAPIView(DestroyAPIView):
    queryset = Training.objects.all()
    serializer_class = TrainingSerializer
    permission_classes = [IsAuthenticated]  # Add any permission classes you need


class TrainingPartCreateAPIView(CreateAPIView):
    queryset = TrainingPart.objects.all()
    serializer_class = TrainingPartSerializer

class TrainingPartUpdateAPIView(UpdateAPIView):
    queryset = TrainingPart.objects.all()
    serializer_class = TrainingPartSerializer

class LineUpPosCreateAPIView(generics.ListCreateAPIView):
    queryset = LineUpPos.objects.all()
    serializer_class = LineUpPosSerializer


class LineUpPosUpdateAPIView(generics.RetrieveUpdateAPIView):
    queryset = LineUpPos.objects.all()
    serializer_class = LineUpPosSerializer

    def perform_update(self, serializer):
        serializer.save()  # Use partial=True to allow partial updates
@api_view(['DELETE'])
def delete_training_part(request, pk):
    try:
        training_part = TrainingPart.objects.get(pk=pk)
    except TrainingPart.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    training_part.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)
class CurrentSeasonFilterAPIView(generics.ListAPIView):
    queryset = CurrentSeason.objects.all()
    serializer_class = CurrentSeasonSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        club = self.request.query_params.get('club')

        if club:
            queryset = queryset.filter(club=club)

        return queryset

class TeamsAPIView(generics.ListAPIView):
    queryset = Team.objects.order_by('name')
    serializer_class = TeamSerializer

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
        else:
            queryset = queryset.order_by('-date')

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

def get_csrf_token(request):
    csrf_token = csrf.get_token(request)
    return JsonResponse({'csrf_token': csrf_token})
