from rest_framework import serializers
from django.utils.timezone import make_aware
from datetime import datetime, timedelta

from .models import Game, User, Club, Team, Availability, Attendance, Training, CurrentSeason, HistoricalGame, Links
from waatea_2.users.models import UserProfile, Classification, Abonnement, Assessment

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

class LinksSerializer(serializers.ModelSerializer):
    class Meta:
        model = Links
        fields = ['pk', 'name', 'icon', 'url']

class ClassificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classification
        fields = ['pk', 'name', 'icon']

class AssessmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Assessment
        fields = ['pk', 'name', 'icon']

class AbonnementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Abonnement
        fields = ['pk', 'name']

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


class ClassificationField(serializers.PrimaryKeyRelatedField):
    def to_representation(self, obj):
        # Serialize the Classification object when retrieving data
        classification = Classification.objects.get(id=obj)
        return ClassificationSerializer(classification).data

    def to_internal_value(self, data):
        # Accept an integer for updating
        try:
            return Classification.objects.get(id=data)
        except Classification.DoesNotExist:
            raise serializers.ValidationError("Invalid Classification ID")


class ClassificationField(serializers.PrimaryKeyRelatedField):
    def __init__(self, **kwargs):
        kwargs['queryset'] = Classification.objects.all()
        kwargs['allow_null'] = True  # Allow the classification field to be null
        super().__init__(**kwargs)


class UserProfileSerializer(serializers.ModelSerializer):
    classification = ClassificationField()

    class Meta:
        model = UserProfile
        fields = ('assessment', 'is_playing', 'permission', 'abo', 'comment', 'classification', 'mobile_phone')

    def to_representation(self, instance):
        data = super().to_representation(instance)
        classification_id = data.get('classification')
        if classification_id is not None:
            classification = Classification.objects.get(id=classification_id)
            data['classification'] = ClassificationSerializer(classification).data

        assessment_id = data.get('assessment')
        if assessment_id is not None:
            assessment = Assessment.objects.get(id=assessment_id)
            data['assessment'] = AssessmentSerializer(assessment).data

        abonnement_id = data.get('abo')
        if abonnement_id is not None:
            abonnement = Abonnement.objects.get(id=abonnement_id)
            data['abonnement'] = AbonnementSerializer(abonnement).data

        return data

    def update(self, instance, validated_data):
        instance.is_playing = validated_data.get('is_playing', instance.is_playing)
        instance.comment = validated_data.get('comment', instance.comment)
        instance.mobile_phone = validated_data.get('mobile_phone', instance.mobile_phone)

        classification = validated_data.get('classification')

        if classification is None:
            instance.classification = None  # Handle null value
        elif isinstance(classification, Classification):
            instance.classification = classification
        else:
            try:
                instance.classification = Classification.objects.get(id=classification)
            except Classification.DoesNotExist:
                raise serializers.ValidationError("Invalid Classification ID")

        assessment = validated_data.get('assessment')

        if assessment is None:
            instance.assessment = None  # Handle null value
        elif isinstance(assessment, Assessment):
            instance.assessment = assessment
        else:
            try:
                instance.assessment = Assessment.objects.get(id=assessment)
            except Assessment.DoesNotExist:
                raise serializers.ValidationError("Invalid Assessment ID")


        abo = validated_data.get('abo')

        if abo is None:
            instance.abo = None  # Handle null value
        elif isinstance(abo, Abonnement):
            instance.abo = abo
        else:
            try:
                instance.abo = Abonnement.objects.get(id=abo)
            except Abonnement.DoesNotExist:
                raise serializers.ValidationError("Invalid Abonnement ID")

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



