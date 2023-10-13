import 'package:flutter/material.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/widgets/playertile.dart';
import 'package:waatea2_client/widgets/rowtile.dart';

class AvailabilityScreen extends StatefulWidget {
  final List<ShowAvailabilityDetailModel> availablePlayers;

  AvailabilityScreen({required this.availablePlayers});

  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  List<ShowAvailabilityDetailModel> column1Players = [];
  List<ShowAvailabilityDetailModel> column2Players = [];

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
              return Draggable<ShowAvailabilityDetailModel>(
                data: player,
                child: PlayerTile(player: player),
                feedback: PlayerTile(player: player, isDragging: true),
                childWhenDragging: SizedBox.shrink(),
              );
            }).toList(),
          ),
          // Second Column (Drag Target)
          Expanded(
            child: DragTarget<ShowAvailabilityDetailModel>(
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  itemCount: 23, // Limit to 23 rows
                  itemBuilder: (context, index) {
                    ShowAvailabilityDetailModel? player;
                    if (index < column1Players.length) {
                      // Render player if available
                      player = column1Players[index];
                    }
                    return Draggable<ShowAvailabilityDetailModel>(
                      data: player,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: RowTile(player: player!, index: index),
                      ),
                      feedback: RowTile(
                          player: player, index: index, isDragging: true),
                      childWhenDragging: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        height: 50, // Adjust the height as needed
                      ),
                      onDragCompleted: () {
                        // Remove the player from the source row if it was dragged to another row
                        if (player != null && player != candidateData) {
                          setState(() {
                            column1Players.remove(player);
                          });
                        }
                      },
                      onDraggableCanceled: (Velocity velocity, Offset offset) {
                        // Reorder players within the same column
                        if (player != null && player == candidateData) {
                          setState(() {
                            column1Players.remove(player);
                            column1Players.insert(index, player!);
                          });
                        }
                      },
                    );
                  },
                );
              },
              onWillAccept: (player) {
                return column1Players.length < 23; // Limit to 23 players
              },
              onAccept: (player) {
                setState(() {
                  column1Players.add(player);
                });
              },
            ),
          ),
          // Third Column (Drag Target)
          Expanded(
            child: DragTarget<ShowAvailabilityDetailModel>(
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  itemCount: 23, // Limit to 23 rows
                  itemBuilder: (context, index) {
                    ShowAvailabilityDetailModel? player;
                    if (index < column2Players.length) {
                      // Render player if available
                      player = column2Players[index];
                    }
                    return Draggable<ShowAvailabilityDetailModel>(
                      data: player,
                      feedback: RowTile(
                          player: player!, index: index, isDragging: true),
                      childWhenDragging: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        height: 50, // Adjust the height as needed
                      ),
                      onDragCompleted: () {
                        // Remove the player from the source row if it was dragged to another row
                        if (player != null && player != candidateData) {
                          setState(() {
                            column2Players.remove(player);
                          });
                        }
                      },
                      onDraggableCanceled: (Velocity velocity, Offset offset) {
                        // Reorder players within the same column
                        if (player != null && player == candidateData) {
                          setState(() {
                            column2Players.remove(player);
                            column2Players.insert(index, player!);
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: RowTile(player: player, index: index),
                      ),
                    );
                  },
                );
              },
              onWillAccept: (player) {
                return column2Players.length < 23; // Limit to 23 players
              },
              onAccept: (player) {
                setState(() {
                  column2Players.add(player);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
