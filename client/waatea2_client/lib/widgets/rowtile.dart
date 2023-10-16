import 'package:flutter/material.dart';
import 'package:waatea2_client/models/availability_model.dart';
import 'package:waatea2_client/models/showavailability_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';

class RowTile extends StatelessWidget {
  final ShowAvailabilityDetailModel player;
  final int index;
  final bool isDragging;

  RowTile({required this.player, required this.index, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Customize the appearance of the row tile
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey : Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Text('${index + 1}: ${player.name}'),
    );
  }
}
