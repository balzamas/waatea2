from rest_framework import serializers
from django.utils.timezone import make_aware
from datetime import datetime, timedelta

from .models import Game, User, Club, Team, Availability, Attendance, Training, CurrentSeason, HistoricalGame
from waatea_2.users.models import UserProfile

class HistoricalGameSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistoricalGame
        fields = [
        'played_for',
        'played_against',
        'position',
        'competition',
        'date'
        ]
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

class GameAvailCountSerializer(serializers.ModelSerializer):
    home = TeamSerializer()
    away = TeamSerializer()
    avail = serializers.SerializerMethodField()
    noavail = serializers.SerializerMethodField()
    maybe = serializers.SerializerMethodField()
    notset = serializers.SerializerMethodField()

    class Meta:
        model = Game
        fields = [
        'pk',
        'home',
        'away',
        'club',
        'date',
        'dayofyear',
        'season',
            'avail',
            'noavail',
            'maybe',
            'notset',
        ]

    def get_avail(self, obj):
        return Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, state=3).count()

    def get_maybe(self, obj):
        return Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, state=2).count()

    def get_noavail(self, obj):
        return Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, state=1).count()

    def get_notset(selfself, obj):
        usercount = User.objects.filter(club=obj.club, userprofile__is_playing=True).count()
        return usercount - Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season).count()


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ('level','is_playing','permission', 'abonnement', 'comment')

    def update(self, instance, validated_data):
        print(instance.level)
        print(instance.is_playing)
        instance.level = validated_data.get('level', instance.level)
        instance.is_playing = validated_data.get('is_playing', instance.is_playing)
        instance.abonnement = validated_data.get('abonnement', instance.abonnement)
        instance.comment = validated_data.get('comment', instance.comment)

        instance.save()

        return instance

class UserSerializer(serializers.ModelSerializer):
    club = ClubSerializer()
    profile = UserProfileSerializer(source='userprofile')
    class Meta:
        model = User
        fields = [
        'pk',
        'name',
        'email',
        'club',
        'mobile_phone',
        'profile'
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
    current = serializers.SerializerMethodField()

    def get_attendance_count(self, obj):
        return obj.attendances.filter(attended=True).count()
    def get_current(self, obj):
        date = obj.date

        if date > (make_aware(datetime.now())-timedelta(hours=23)) and date < (make_aware(datetime.now())+timedelta(hours=23)):
            return True
        else:
            return False

    class Meta:
        model = Training
        fields = '__all__'

class TrainingAttendanceSerializer(serializers.ModelSerializer):
    attended = serializers.SerializerMethodField()

    class Meta:
        model = Training
        fields = ['date', 'attended']

    def get_attended(self, obj):
        user_id = self.context.get('user_id')
        print("-------")
        print(self.context)
        print(user_id)
        if user_id is not None:
            return obj.attendances.filter(player_id=user_id, attended=True).exists()
        return False

class CurrentSeasonSerializer(serializers.ModelSerializer):
    class Meta:
        model = CurrentSeason
        fields = [
        'pk',
        'club',
        'season',
        ]



