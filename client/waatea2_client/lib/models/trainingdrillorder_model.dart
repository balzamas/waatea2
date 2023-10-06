import 'package:waatea2_client/models/drill_model.dart';

class TrainingDrillOrderModel {
  final int? id; // Change the data type if necessary
  final String training; // Change the data type if necessary
  final DrillModel drill; // Use the DrillModel
  final int? order;

  TrainingDrillOrderModel({
    required this.id,
    required this.training,
    required this.drill,
    required this.order,
  });

  factory TrainingDrillOrderModel.fromJson(Map<String, dynamic> json) {
    return TrainingDrillOrderModel(
      id: json['id'],
      training: json['training'],
      drill: DrillModel.fromJson(json['drill']),
      order: json['order'],
    );
  }
}
