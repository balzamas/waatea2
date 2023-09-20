import 'package:waatea2_client/models/userprofile_model.dart';

class UserModel {
  final int pk;
  final String name;
  final String email;
  final UserProfileModel profile;
  final int attendance_percentage;

  UserModel(
      {required this.pk,
      required this.name,
      required this.email,
      required this.profile,
      required this.attendance_percentage});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        pk: json['pk'],
        name: json['name'],
        email: json['email'],
        profile: UserProfileModel.fromJson(json['profile']),
        attendance_percentage: json['attendance_percentage']);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };
}
