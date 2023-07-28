from datetime import datetime

from rest_framework import viewsets, generics
from rest_framework.generics import UpdateAPIView, CreateAPIView
from .models import Game, User, Availability
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer

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
        game = self.request.query_params.get('game')
        player = self.request.query_params.get('player')

        if game and player:
            queryset = queryset.filter(game=game, player=player)
        elif game:
            queryset = queryset.filter(game=game)



        return queryset

class AvailabilityUpdateAPIView(UpdateAPIView):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer

class AvailabilityCreateAPIView(CreateAPIView):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer
