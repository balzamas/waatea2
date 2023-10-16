import 'package:flutter/material.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';
import 'package:waatea2_client/widgets/playertile.dart';
import 'package:waatea2_client/widgets/playertile23.dart';
import 'package:waatea2_client/models/selectedplayer_model.dart';

class AvailabilityScreen extends StatefulWidget {
  final List<ShowAvailabilityDetailModel> availablePlayers;

  AvailabilityScreen({required this.availablePlayers});

  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class PlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Center(
        child: Text(
          'Empty',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  List<SelectedPlayer> column1Players =
      List.filled(23, SelectedPlayer(playerId: -1, position: -1, gameId: -1));
  List<SelectedPlayer> column2Players =
      List.filled(23, SelectedPlayer(playerId: -1, position: -1, gameId: -1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Availability Screen'),
      ),
      body: Row(
        children: [
          // First Column (Available Players)
          Column(
            children: widget.availablePlayers
                .where((player) => player.state == 2 || player.state == 3)
                .map((player) {
              Color backgroundColor = Colors.white;
              if (column1Players.any((p) => p.playerId == player.pk)) {
                backgroundColor = Colors.green;
              }
              return Draggable<SelectedPlayer>(
                data:
                    SelectedPlayer(playerId: player.pk, position: 0, gameId: 0),
                child: PlayerTile(
                  player: player,
                  backgroundColor: backgroundColor,
                ),
                feedback: PlayerTile(
                  player: player,
                  isDragging: true,
                  backgroundColor: backgroundColor,
                ),
                childWhenDragging: SizedBox.shrink(),
              );
            }).toList(),
          ),

          // Second Column (ReorderableListView)
// Second Column (ReorderableListView)
          Expanded(
            child: ReorderableListView.builder(
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  final player = column1Players[oldIndex];
                  column1Players[oldIndex] = column1Players[newIndex];
                  column1Players[newIndex] = player;
                });
              },
              itemCount: column1Players.length,
              itemBuilder: (context, index) {
                final player = column1Players[index];
                final isPlayerEmpty =
                    player.playerId == -1; // Check if the player is empty
                final uniqueKey = isPlayerEmpty
                    ? Key('empty_$index') // Use a unique key for empty lines
                    : Key(
                        '${player.playerId}_$index'); // Combine player ID and index
                return ReorderableDelayedDragStartListener(
                  index: index,
                  child: Container(
                    key: uniqueKey, // Key for reordering
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: isPlayerEmpty
                        ? PlaceholderWidget() // Display a placeholder for empty lines
                        : PlayerTile23(
                            player: player,
                            backgroundColor: Colors
                                .green, // Use the appropriate background color
                          ),
                  ),
                );
              },
            ),
          ),

// Third Column (ReorderableListView)
          Expanded(
            child: ReorderableListView.builder(
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  final player = column2Players[oldIndex];
                  column2Players[oldIndex] = column2Players[newIndex];
                  column2Players[newIndex] = player;
                });
              },
              itemCount: column2Players.length,
              itemBuilder: (context, index) {
                final player = column2Players[index];
                final isPlayerEmpty =
                    player.playerId == -1; // Check if the player is empty
                final uniqueKey = isPlayerEmpty
                    ? Key('empty_$index') // Use a unique key for empty lines
                    : Key(
                        '${player.playerId}_$index'); // Combine player ID and index
                return ReorderableDelayedDragStartListener(
                  index: index,
                  child: Container(
                    key: uniqueKey, // Key for reordering
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: isPlayerEmpty
                        ? PlaceholderWidget() // Display a placeholder for empty lines
                        : PlayerTile23(
                            player: player,
                            backgroundColor: Colors
                                .blue, // Use the appropriate background color
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
