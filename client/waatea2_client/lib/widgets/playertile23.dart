import 'package:flutter/material.dart';
import 'package:waatea2_client/models/selectedplayer_model.dart';

class PlayerTile23 extends StatelessWidget {
  final SelectedPlayer player;
  final bool isDragging;
  final Color backgroundColor;

  PlayerTile23({
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
      child: Text(
          "Player ID: ${player.playerId}, Position: ${player.position}, Game ID: ${player.gameId}"),
    );
  }
}
