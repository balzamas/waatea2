import 'package:waatea2_client/models/userprofile_model.dart';

class UserModel {
  final int pk;
  final String name;
  final String email;
  final UserProfileModel profile;

  UserModel({
    required this.pk,
    required this.name,
    required this.email,
    required this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      pk: json['pk'],
      name: json['name'],
      email: json['email'],
      profile: UserProfileModel.fromJson(json['profile']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };
}
