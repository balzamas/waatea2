class UserProfileModel {
  final int level;
  // Add other profile fields as needed

  UserProfileModel({required this.level});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      level: json['level'],
      // Parse other profile fields from JSON if available
    );
  }
}
