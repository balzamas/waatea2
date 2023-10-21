import 'package:flutter/material.dart';
import 'package:waatea2_client/models/availability_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';

class PlayerTile extends StatelessWidget {
  final ShowAvailabilityDetailModel player;
  final bool isDragging;
  final Color backgroundColor;

  PlayerTile({
    required this.player,
    this.isDragging = false,
    this.backgroundColor = Colors.white, // Default background color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey : backgroundColor,
        border: Border.all(color: Colors.black),
      ),
      child: Text("${player.name} ${player.attendance_percentage}%"),
    );
  }
}