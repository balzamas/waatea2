class UserProfileModel {
  final int level;
  final bool isPlaying;
  // Add other profile fields as needed

  UserProfileModel({required this.level, required this.isPlaying});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(level: json['level'], isPlaying: json['is_playing']
        // Parse other profile fields from JSON if available
        );
  }
}
