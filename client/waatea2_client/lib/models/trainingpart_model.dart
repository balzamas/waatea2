class TrainingPart {
  late final String? id;
  late final String trainingId;
  int minutes;
  String description;
  final int? order;

  TrainingPart({
    required this.id,
    required this.trainingId,
    required this.minutes,
    this.description = "",
    required this.order,
  });

  factory TrainingPart.fromJson(Map<String, dynamic> json) {
    return TrainingPart(
        id: json['id'],
        trainingId: json['training'],
        description: json['description'],
        order: json['order'],
        minutes: json['minutes']);
  }
}
