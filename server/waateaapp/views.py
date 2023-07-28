from django.shortcuts import render, redirect
from .models import Game, User, Availability
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer
from rest_framework import viewsets


# Create your views here.
class Game(viewsets.ModelViewSet):
    queryset = Game.objects.all()
    serializer_class = GameSerializer

class User(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class Availability(viewsets.ModelViewSet):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer



def get_games_by_club(club_id):
    return Game.objects.get(club=club_id)


def get_availability_by_game_and_player(game_id, player_id):
    return Availability.objects.get(game=game_id, player=player_id)
