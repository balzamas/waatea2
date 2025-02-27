from rest_framework import serializers
from django.utils.timezone import make_aware
from datetime import datetime, timedelta
from rest_framework.exceptions import ValidationError
from .models import Game, User, Club, Team, Availability, Attendance, Training, CurrentSeason, HistoricalGame, Links, \
    TrainingPart, LineUpPos, Fitness
from waatea_2.users.models import UserProfile, Classification, Abonnement, Assessment, Position
from django.db.models import Sum

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
        fields = ['pk', 'name', 'short']

class PositionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Position
        fields = ['pk', 'position']


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
        'season',
            'lineup_published'
        ]

class GameCreateSerializer(serializers.ModelSerializer):
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
            'lineup_published'
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
        return Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, state=3, player__userprofile__is_playing=True, player__club=obj.club).count()

    def get_maybe(self, obj):
        return Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, state=2, player__userprofile__is_playing=True, player__club=obj.club).count()

    def get_noavail(self, obj):
        return Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, state=1, player__userprofile__is_playing=True, player__club=obj.club).count()

    def get_notset(selfself, obj):
        usercount = User.objects.filter(club=obj.club, userprofile__is_playing=True).count()
        return usercount - Availability.objects.filter(dayofyear=obj.dayofyear, season=obj.season, player__userprofile__is_playing=True, player__club=obj.club).count()


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

class PositionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Position
        fields = [
        'pk',
        'position',
        ]

class UserProfileSerializer(serializers.ModelSerializer):
    classification = ClassificationField()
    positions = PositionSerializer(many=True)  # Add positions field

    class Meta:
        model = UserProfile
        fields = ('assessment', 'is_playing', 'permission', 'abo', 'comment', 'classification', 'mobile_phone', 'positions')

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

        positions_data = validated_data.get('positions')

        if positions_data is not None:
            instance.positions.clear()  # Clear existing positions
            for position_data in positions_data:
                position, created = Position.objects.get_or_create(position=position_data['position'])
                instance.positions.add(position)

        instance.save()
        return instance


class UserSerializer(serializers.ModelSerializer):
    attendance_percentage = serializers.SerializerMethodField()
    caps = serializers.SerializerMethodField()
    fitness = serializers.SerializerMethodField()

    club = ClubSerializer()
    profile = UserProfileSerializer(source='userprofile')
    class Meta:
        model = User
        fields = [
        'pk',
        'name',
        'email',
        'club',
        'profile',
            'attendance_percentage',
            'caps',
            'fitness'
        ]

    def get_caps(self, obj):
        return HistoricalGame.objects.filter(player=obj.pk).order_by('-date').count()

    def get_attendance_percentage(self, obj):
        season = CurrentSeason.objects.get(club=obj.club)

        #ToDo: check if there are less then 10 trainings yet and calculate accordingly
        # Step 1: Retrieve the last 10 training records.
        last_10_trainings = Training.objects.filter(date__lte=datetime.now(), season=season.season).order_by('-date')[:10]

        # Step 2: Filter the attendances for the specified player and last 10 trainings.
        count = Attendance.objects.filter(player=obj.pk, attended=True, training__in=last_10_trainings).count()

        percentage = 0

        if count > 0:
                percentage = int(100 * count / 10)

        return percentage

    def get_fitness(self, obj):

        #ToDo: past 6 weeks

        season = CurrentSeason.objects.get(club=obj.club)


        fitness_records = Fitness.objects.filter(player=obj.pk, season=season.season)

        total_points = fitness_records.aggregate(Sum('points'))['points__sum'] or 0

        return total_points

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

class FitnessSerializer(serializers.ModelSerializer):
    player_name = serializers.SerializerMethodField()
    class Meta:
        model = Fitness
        fields = [
        'pk',
        'player',
            'player_name',
        'date',
        'season',
        'points',
        'note'
        ]

    def get_player_name(self, obj):
        return obj.player.name

class TrainingSerializer(serializers.ModelSerializer):

    class Meta:
        model = Training
        fields = '__all__'

class TeamSerializer(serializers.ModelSerializer):

    class Meta:
        model = Team
        fields = '__all__'

class TrainingAttendanceCountSerializer(serializers.ModelSerializer):
    attendance_count = serializers.SerializerMethodField()
    nonattendance_count = serializers.SerializerMethodField()
    current = serializers.SerializerMethodField()

    def get_attendance_count(self, obj):
        return obj.attendances.filter(attended=True).count()

    def get_nonattendance_count(self, obj):
        return obj.attendances.filter(attended=False).count()
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

class TrainingPartSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainingPart
        fields = '__all__'

class LineUpPosSerializer(serializers.ModelSerializer):
    player_id = serializers.IntegerField(write_only=True, required=False)
    game_id = serializers.UUIDField(write_only=True, required=False)
    player = UserSerializer(read_only=True)
    game = GameSerializer(read_only=True)

    class Meta:
        model = LineUpPos
        fields = '__all__'

    def create(self, validated_data):
        player_id = validated_data.pop('player_id', None)
        game_id = validated_data.pop('game_id', None)

        if player_id is not None:
            try:
                player = User.objects.get(id=player_id)
            except User.DoesNotExist:
                raise ValidationError("Player with provided ID does not exist.")
        else:
            player = None

        if game_id is not None:
            try:
                game = Game.objects.get(id=game_id)
            except Game.DoesNotExist:
                raise ValidationError("Game with provided ID does not exist.")
        else:
            game = None

        lineup_pos = LineUpPos.objects.create(player=player, game=game, **validated_data)
        return lineup_pos

    def update(self, instance, validated_data):
        player_id = validated_data.pop('player_id', None)
        game_id = validated_data.pop('game_id', None)

        print("xxxxxx")
        print(player_id)

        if player_id is not None:
            player = User.objects.get(id=player_id)
            instance.player = player
        else:
            instance.player = None

        if game_id is not None:
            game = Game.objects.get(id=game_id)
            instance.game = game

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance
