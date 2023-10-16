import 'dart:math';

import 'package:flutter/material.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/column2player_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';
import 'package:uuid/uuid.dart';

class YourScreen extends StatefulWidget {
  final List<ShowAvailabilityDetailModel> availablePlayers;

  YourScreen({required this.availablePlayers});

  @override
  _YourScreenState createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  List<Column2PlayerModel> column2Players = List.generate(
    23,
    (index) => Column2PlayerModel(
      playerid: 0,
      name: "-",
      fieldid: Uuid(),
    ),
  );

  List<Column2PlayerModel> column3Players = List.generate(
    23,
    (index) => Column2PlayerModel(
      playerid: 0,
      name: "-",
      fieldid: Uuid(),
    ),
  );

  Set<int> playerIdsInColumn2 = Set();
  Set<int> playerIdsInColumn3 = Set();

  @override
  Widget build(BuildContext context) {
    final List<ShowAvailabilityDetailModel> availablePlayersFiltered = widget
        .availablePlayers
        .where((player) => player.state == 2 || player.state == 3)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("Player Selection Screen"),
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text("Avail."),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: availablePlayersFiltered.length,
                    itemBuilder: (context, index) {
                      final startIndex = index * 2;
                      final endIndex = startIndex + 2;
                      return Row(
                        children: [
                          for (int i = startIndex; i < endIndex; i++)
                            if (i < availablePlayersFiltered.length &&
                                (availablePlayersFiltered[i].state == 2 ||
                                    availablePlayersFiltered[i].state == 3))
                              Flexible(
                                child: Draggable(
                                  data: availablePlayersFiltered[i],
                                  feedback: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                          availablePlayersFiltered[i].name),
                                    ),
                                  ),
                                  child: Card(
                                    color: playerIdsInColumn2.contains(
                                                availablePlayersFiltered[i]
                                                    .pk) &&
                                            playerIdsInColumn3.contains(
                                                availablePlayersFiltered[i].pk)
                                        ? Colors
                                            .grey // Player is in both columns
                                        : playerIdsInColumn2.contains(
                                                availablePlayersFiltered[i].pk)
                                            ? Colors
                                                .green // Player is only in team 1
                                            : playerIdsInColumn3.contains(
                                                    availablePlayersFiltered[i]
                                                        .pk)
                                                ? Colors
                                                    .blue // Player is only in team 2
                                                : null, // Default background color
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(availablePlayersFiltered[i]
                                                  .name),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              returnStateIcon(
                                                  availablePlayersFiltered[i]
                                                      .state),
                                              Icon(
                                                availablePlayersFiltered[i]
                                                            .playerProfile
                                                            .classification
                                                            ?.icon !=
                                                        null
                                                    ? IconData(
                                                        int.parse(
                                                            '0x${availablePlayersFiltered[i].playerProfile.classification!.icon}'),
                                                        fontFamily:
                                                            'MaterialIcons',
                                                      )
                                                    : Icons.highlight_off,
                                              ),
                                              Text(
                                                "${availablePlayersFiltered[i].attendance_percentage}%",
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green, // Border color for Team 2
                  width: 2, // Border width
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text("Team 1"),
                    DragTarget(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          height: 800, // Adjust the height as needed
                          child: ReorderableListView(
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                final movedPlayer =
                                    column2Players.removeAt(oldIndex);
                                column2Players.insert(newIndex, movedPlayer);

                                // Check if the player was moved to column 2
                                if (newIndex <
                                    availablePlayersFiltered.length) {
                                  // Check if the player ID is not in column 2 already
                                  if (playerIdsInColumn2
                                      .contains(movedPlayer.playerid)) {
                                    // Player is already in column 2, do not update
                                    return;
                                  }

                                  // Update player ID and name
                                  movedPlayer.playerid =
                                      availablePlayersFiltered[newIndex].pk;
                                  movedPlayer.name =
                                      availablePlayersFiltered[newIndex].name;

                                  column2Players[oldIndex].playerid = 0;
                                  column2Players[oldIndex].name = "-";

                                  // Add the player ID to the set of IDs in column 2
                                  setState(() {
                                    playerIdsInColumn2
                                        .add(movedPlayer.playerid);
                                  });
                                } else {
                                  // Player was moved out of column 2, remove their ID from the set
                                  playerIdsInColumn2
                                      .remove(movedPlayer.playerid);
                                }
                              });
                            },
                            children: column2Players.map<Widget>((player) {
                              final index = column2Players.indexOf(player) + 1;
                              return GestureDetector(
                                key: ValueKey<Uuid>(player.fieldid),
                                onDoubleTap: () {
                                  // Double-clicked, remove the player
                                  setState(() {
                                    playerIdsInColumn2.remove(player.playerid);
                                    player.playerid = 0;
                                    player.name = "-";
                                  });
                                },
                                child: ListTile(
                                  title: Text(
                                    player.name.isEmpty
                                        ? "Empty"
                                        : "$index: ${player.name}",
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      onAccept: (ShowAvailabilityDetailModel player) {
                        // Handle the player being dropped into Column 2
                        if (!playerIdsInColumn2.contains(player.pk)) {
                          final emptySlot =
                              column2Players.indexWhere((c) => c.playerid == 0);
                          if (emptySlot != -1) {
                            column2Players[emptySlot].playerid = player.pk;
                            column2Players[emptySlot].name = player.name;
                            setState(() {
                              playerIdsInColumn2.add(player.pk);
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue, // Border color for Team 2
                  width: 2, // Border width
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text("Team 2"),
                    DragTarget(
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          height: 800, // Adjust the height as needed
                          child: ReorderableListView(
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                final movedPlayer =
                                    column3Players.removeAt(oldIndex);
                                column3Players.insert(newIndex, movedPlayer);

                                // Check if the player was moved to column 2
                                if (newIndex <
                                    availablePlayersFiltered.length) {
                                  // Check if the player ID is not in column 2 already
                                  if (playerIdsInColumn3
                                      .contains(movedPlayer.playerid)) {
                                    // Player is already in column 2, do not update
                                    return;
                                  }

                                  // Update player ID and name
                                  movedPlayer.playerid =
                                      availablePlayersFiltered[newIndex].pk;
                                  movedPlayer.name =
                                      availablePlayersFiltered[newIndex].name;

                                  column3Players[oldIndex].playerid = 0;
                                  column3Players[oldIndex].name = "-";

                                  // Add the player ID to the set of IDs in column 2
                                  setState(() {
                                    playerIdsInColumn3
                                        .add(movedPlayer.playerid);
                                  });
                                } else {
                                  // Player was moved out of column 2, remove their ID from the set
                                  playerIdsInColumn3
                                      .remove(movedPlayer.playerid);
                                }
                              });
                            },
                            children: column3Players.map<Widget>((player) {
                              final index = column3Players.indexOf(player) + 1;
                              return GestureDetector(
                                key: ValueKey<Uuid>(player.fieldid),
                                onDoubleTap: () {
                                  // Double-clicked, remove the player
                                  setState(() {
                                    playerIdsInColumn3.remove(player.playerid);
                                    player.playerid = 0;
                                    player.name = "-";
                                  });
                                },
                                child: ListTile(
                                  title: Text(
                                    player.name.isEmpty
                                        ? "Empty"
                                        : "$index: ${player.name}",
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      onAccept: (ShowAvailabilityDetailModel player) {
                        // Handle the player being dropped into Column 2
                        if (!playerIdsInColumn3.contains(player.pk)) {
                          final emptySlot =
                              column3Players.indexWhere((c) => c.playerid == 0);
                          if (emptySlot != -1) {
                            column3Players[emptySlot].playerid = player.pk;
                            column3Players[emptySlot].name = player.name;
                            setState(() {
                              playerIdsInColumn3.add(player.pk);
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
