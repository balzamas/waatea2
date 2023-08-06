from django.shortcuts import render, redirect
from .models import Game, User, Availability, Club
from .serializers import GameSerializer, UserSerializer, AvailabilitySerializer, ClubSerializer
from rest_framework import viewsets
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authentication import SessionAuthentication, BasicAuthentication


class Game(viewsets.ModelViewSet):
    queryset = Game.objects.all()
    serializer_class = GameSerializer

class ClubViewSet(viewsets.ModelViewSet):
    queryset = Club.objects.all()
    serializer_class = ClubSerializer

    # Set the default permission_classes to require authentication for standard actions
    permission_classes = [IsAuthenticated]
    authentication_classes = [SessionAuthentication, BasicAuthentication]

    # Override the get_permissions method to allow access without authentication for the custom action
    def get_permissions(self):
        if self.action == 'allclubs':
            self.permission_classes = [AllowAny]
        return super(ClubViewSet, self).get_permissions()

    @action(detail=False, methods=['get'])
    def allclubs(self, request):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

class User(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class Availability(viewsets.ModelViewSet):
    queryset = Availability.objects.all()
    serializer_class = AvailabilitySerializer
