class ShowAvailabilityDetailModel {
  final int pk;
  final String name;
  final String email;
  final int level;
  final String mobilephone;
  int state;

  ShowAvailabilityDetailModel(
      {required this.pk,
      required this.name,
      required this.email,
      required this.level,
      required this.mobilephone,
      required this.state});

  factory ShowAvailabilityDetailModel.fromJson(Map<String, dynamic> json) {
    return ShowAvailabilityDetailModel(
        pk: json['pk'],
        name: json['name'],
        email: json['email'],
        level: json['level'],
        mobilephone: json['mobile_phone'],
        state: 0);
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'name': name,
        'email': email,
        'level': level,
        'mobilephone': mobilephone,
      };
}
