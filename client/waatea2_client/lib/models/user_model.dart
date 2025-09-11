import 'package:waatea2_client/models/userprofile_model.dart';

class UserModel {
  final int pk;
  final String name;
  final String email;
  final UserProfileModel profile;
  final int attendancePercentage;
  final int fitness;
  final int caps;
  final double clubHours;


  UserModel(
      {required this.pk,
      required this.name,
      required this.email,
      required this.profile,
      required this.attendancePercentage,
      required this.caps,
      required this.fitness,
      required this.clubHours,});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      pk: json['pk'],
      name: json['name'],
      email: json['email'],
      profile: UserProfileModel.fromJson(json['profile']),
      attendancePercentage: json['attendance_percentage'],
      caps: json['caps'],
      fitness: json['fitness'],
      clubHours: (json['club_hours'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };
}
