# serializers.py
from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('name', 'email', 'password', 'mobile_phone', 'club')  # Update with your User model fields
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User(
            name=validated_data['name'],
            email=validated_data['email'],
            mobile_phone=validated_data['mobile_phone'],
            club=validated_data['club'],
            level = 5
        )
        user.set_password(validated_data['password'])
        user.save()
        return user
