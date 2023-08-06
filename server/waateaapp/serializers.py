from rest_framework import serializers

from .models import Game, User, Club, Team, Availability, Attendance, Training, CurrentSeason

class ClubSerializer(serializers.ModelSerializer):
    class Meta:
        model = Club
        fields = [
        'pk',
        'name',
        ]

class TeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = [
        'pk',
        'name',
        ]
class GameSerializer(serializers.ModelSerializer):
    home = TeamSerializer()
    away = TeamSerializer()
    class Meta:
        model = Game
        fields = [
        'pk',
        'home',
        'away',
        'club',
        'date',
        'dayofyear',
        'season'
        ]


class UserSerializer(serializers.ModelSerializer):
    club = ClubSerializer()
    class Meta:
        model = User
        fields = [
        'pk',
        'name',
        'email',
        'club',
        'mobile_phone',
        'level'
        ]

class AvailabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Availability
        fields = [
        'pk',
        'player',
        'state',
        'club',
        'dayofyear',
            'season',
            'updated'
        ]

class AttendanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attendance
        fields = [
        'pk',
        'player',
        'attended',
        'dayofyear',
            'season',
            'training'
        ]

class TrainingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Training
        fields = [
        'pk',
        'club',
        'date',
            'dayofyear',
            'season',
        ]

class TrainingAttendanceCountSerializer(serializers.ModelSerializer):
    attendance_count = serializers.SerializerMethodField()

    def get_attendance_count(self, obj):
        return obj.attendances.filter(attended=True).count()

    class Meta:
        model = Training
        fields = '__all__'

class CurrentSeasonSerializer(serializers.ModelSerializer):
    class Meta:
        model = CurrentSeason
        fields = [
        'pk',
        'club',
        'season',
        ]
