import 'package:flutter/material.dart';
import 'package:waatea2_client/models/availability_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';

class PlayerTile extends StatelessWidget {
  final ShowAvailabilityDetailModel player;
  final bool isDragging;

  PlayerTile({required this.player, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Customize the appearance of the player tile
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey : Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Text(player.name),
    );
  }
}
