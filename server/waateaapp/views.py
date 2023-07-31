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
