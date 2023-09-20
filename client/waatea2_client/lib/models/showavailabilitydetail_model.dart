import 'package:waatea2_client/models/userprofile_model.dart';

class ShowAvailabilityDetailModel {
  final int pk;
  final String name;
  final String email;
  final UserProfileModel playerProfile;
  final String mobilephone;
  final int attendance_percentage;
  int state;
  String updated;

  ShowAvailabilityDetailModel(
      {required this.pk,
      required this.name,
      required this.email,
      required this.playerProfile,
      required this.mobilephone,
      required this.attendance_percentage,
      required this.state,
      required this.updated});

  factory ShowAvailabilityDetailModel.fromJson(Map<String, dynamic> json) {
    return ShowAvailabilityDetailModel(
        pk: json['pk'],
        name: json['name'],
        email: json['email'],
        attendance_percentage: json['attendance_percentage'],
        playerProfile: UserProfileModel.fromJson(json['profile']),
        mobilephone: json['profile']['mobile_phone'],
        state: 0,
        updated: "");
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'name': name,
        'email': email,
        'mobilephone': mobilephone,
      };
}
