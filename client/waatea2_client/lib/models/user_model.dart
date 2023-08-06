import 'package:waatea2_client/models/userprofile_model.dart';

class UserModel {
  final int pk;
  final String name;
  final String email;
  final String mobilePhone;
  final UserProfileModel profile;

  UserModel({
    required this.pk,
    required this.name,
    required this.email,
    required this.mobilePhone,
    required this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      pk: json['pk'],
      name: json['name'],
      email: json['email'],
      mobilePhone: json['mobile_phone'],
      profile: UserProfileModel.fromJson(json['profile']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'mobile_phone': mobilePhone,
      };
}
