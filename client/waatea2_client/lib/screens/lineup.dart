import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/lineupeditor_model.dart';
import 'package:waatea2_client/models/game_model.dart';
import 'package:waatea2_client/models/lineuppos_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/screens/showlineup.dart';
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:pdf/widgets.dart' as pw;

import 'package:universal_html/html.dart' as uh;

import '../models/position_model.dart';

class LineUpEditor extends StatefulWidget {
  final List<ShowAvailabilityDetailModel> availablePlayers;
  final int dayoftheyear;
  final String season;

  const LineUpEditor(
      {Key? key, required this.availablePlayers,
      required this.dayoftheyear,
      required this.season}) : super(key: key);

  @override
  _LineUpEditorState createState() => _LineUpEditorState();
}

class _LineUpEditorState extends State<LineUpEditor> {
  late Future<List<GameModel>> games;

  List<LineUpEditorModel> team1Players = List.generate(
    23,
    (index) => LineUpEditorModel(
      posid: index,
      playerid: 0,
      name: "-",
      fieldid: null,
    ),
  );

  List<LineUpEditorModel> team2Players = List.generate(
    23,
    (index) => LineUpEditorModel(
      posid: index,
      playerid: 0,
      name: "-",
      fieldid: null,
    ),
  );

  int selectedPlayerPK = -1; // Track the selected player in the first column
  Set<int> addedPlayersTeam1 =
      {}; // Track players already added to the second column
  int selectedCardIndexTeam1 =
      -1; // Track the index of the selected card in the second column
  Set<int> addedPlayersTeam2 =
      {}; // Track players already added to the third column
  int selectedCardIndexTeam2 =
      -1; // Track the index of the selected card in the third column
  String team1Title = ""; // Initialize with an empty string
  String team1id = ""; // Initialize with an empty string
  String team2Title = ""; // Initialize with an empty string
  String team2id = ""; // Initialize with an empty string
  String selectedPosition = "All";
  late List<ShowAvailabilityDetailModel> availablePlayersFiltered;
  late List<ShowAvailabilityDetailModel> yourOriginalPlayerList;
  List<PositionModel> positionOptions = [];
  double availColWidth = 225;
  double teamsColWidth = 225;

  @override
  void initState() {
    super.initState();
    games = getGameList(widget.season, widget.dayoftheyear);
    //This is ugly bullshit
    games.then((gameList) {
      if (gameList.isNotEmpty) {
        setState(() {
          team1Title =
              "${gameList[0].home}\n${gameList[0].away}"; // Set the title
          team1id = gameList[0].pk;
        });
        Future<List<LineUpPosModel>> playersTeam1 = getLineUp(team1id);
        playersTeam1.then((player1List) {
          for (var player in player1List) {
            setState(() {
              if (player.player != null) {
                team1Players[player.position].name = player.player!.name;
                team1Players[player.position].playerid = player.player!.pk;
                addedPlayersTeam1.add(player.player!.pk);
              }
              team1Players[player.position].fieldid = player.id;
            });
          }
        });
      }

      if (gameList.length > 1) {
        setState(() {
          teamsColWidth = 140;
          availColWidth = 170;
          team2Title =
              "${gameList[1].home}\n${gameList[1].away}"; // Set the title

          team2id = gameList[1].pk;
        });
        Future<List<LineUpPosModel>> playersTeam2 = getLineUp(team2id);
        playersTeam2.then((player2List) {
          for (var player in player2List) {
            setState(() {
              if (player.player != null) {
                team2Players[player.position].name = player.player!.name;
                team2Players[player.position].playerid = player.player!.pk;

                addedPlayersTeam2.add(player.player!.pk);
              }
              team2Players[player.position].fieldid = player.id;
            });
          }
        });
      }
    });

    fetchPositions().then((positions) {
      setState(() {
        positionOptions = positions;
      });
    });

    //Load lineups
    availablePlayersFiltered = widget.availablePlayers
        .where((player) => player.state == 2 || player.state == 3)
        .toList();
    yourOriginalPlayerList = availablePlayersFiltered;
  }

  Future<List<PositionModel>> fetchPositions() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/positions/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => PositionModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load positions');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScrollController scrollControllerPlayerList = ScrollController();
    ScrollController scrollControllerGame1 = ScrollController();
    ScrollController scrollControllerGame2 = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Player Selection Screen",
    style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.publish),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _publish(team1id);
              _publish(team2id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () async {
              final team1Lineup =
                  await getLineUp(team1id); // Load the lineup for team 1
              final team2Lineup =
                  await getLineUp(team2id); // Load the lineup for team 2

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowLineUp(
                    team1Title: team1Title,
                    team1Lineup: team1Lineup,
                    team2Title: team2Title,
                    team2Lineup: team2Lineup,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AlertDialog(
                    title: Text('Saving line up...'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.black),
                        Text('Please wait while the line up is saved.'),
                      ],
                    ),
                  );
                },
              );
              // Call the save method when the save icon is pressed.
              await Future.wait([
                _save(team1Players, team1id),
                if (team2id != "") _save(team2Players, team2id),
              ]);
              Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _generatePDF();
            },
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text("Avail."),
              SizedBox(
                width: 100, // Set the desired width here
                child: DropdownButton<String>(
                    value: selectedPosition,
                    items:
                        _buildPositionDropdownItems(), // Create this function
                    onChanged: (value) {
                      setState(() {
                        selectedPosition = value!;
                        // Call a function to filter the players based on the selected position
                        filterPlayersByPosition();
                      });
                    }),
              ),
              // Scroll Up Button

              ElevatedButton(
                onPressed: () {
                  // Scroll up logic
                  scrollControllerPlayerList.animateTo(
                    scrollControllerPlayerList.offset -
                        300, // Adjust this value as needed
                    curve: Curves.linear,
                    duration: Duration(
                        milliseconds: 5), // Adjust this value as needed
                  );
                },
                child: Icon(Icons.arrow_upward),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  width: availColWidth, // Set the desired width here
                  child: SingleChildScrollView(
                    controller:
                        scrollControllerPlayerList, // Add a ScrollController
                    child: Column(
                      children: <Widget>[
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            return true; // Return true to allow the scroll to continue.
                          },
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availablePlayersFiltered.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                behavior: HitTestBehavior
                                    .translucent, // Allow touch events to pass through
                                onTap: () {
                                  setState(() {
                                    if (selectedPlayerPK ==
                                        availablePlayersFiltered[index].pk) {
                                      selectedPlayerPK =
                                          -1; // Unselect if already selected
                                    } else {
                                      selectedPlayerPK =
                                          availablePlayersFiltered[index].pk;
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 4,
                                      color: selectedPlayerPK ==
                                              availablePlayersFiltered[index].pk
                                          ? Colors
                                              .red // Add a red border if selected
                                          : Colors
                                              .transparent, // No border if not selected
                                    ),
                                  ),
                                  child: Card(
                                    elevation: 2,
                                    color: addedPlayersTeam1.contains(
                                                availablePlayersFiltered[index]
                                                    .pk) &&
                                            addedPlayersTeam2.contains(
                                                availablePlayersFiltered[index]
                                                    .pk)
                                        ? Colors
                                            .grey // Player is in both columns
                                        : addedPlayersTeam1.contains(
                                                availablePlayersFiltered[index]
                                                    .pk)
                                            ? Colors.green.withOpacity(
                                                0.3) // Player is only in team 1
                                            : addedPlayersTeam2.contains(
                                                    availablePlayersFiltered[index]
                                                        .pk)
                                                ? Colors.blue.withOpacity(
                                                    0.3) // Player is only in team 2
                                                : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(availablePlayersFiltered[
                                                      index]
                                                  .name),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              returnStateIcon(
                                                  availablePlayersFiltered[
                                                          index]
                                                      .state,
                                                  true),
                                              Icon(
                                                availablePlayersFiltered[index]
                                                            .playerProfile
                                                            .classification
                                                            ?.icon !=
                                                        null
                                                    ? IconData(
                                                        int.parse(
                                                            '0x${availablePlayersFiltered[index].playerProfile.classification!.icon}'),
                                                        fontFamily:
                                                            'MaterialIcons',
                                                      )
                                                    : Icons.highlight_off,
                                                size: 15,
                                              ),
                                              Text(
                                                  "${availablePlayersFiltered[index].attendance_percentage}%"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  // Scroll down logic
                  scrollControllerPlayerList.animateTo(
                    scrollControllerPlayerList.offset +
                        300, // Adjust this value as needed
                    curve: Curves.linear,
                    duration: Duration(
                        milliseconds: 5), // Adjust this value as needed
                  );
                },
                child: Icon(Icons.arrow_downward),
              ),
            ],
          ),
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(team1Title, textScaleFactor: 0.8),
            IconButton(
              icon: const Icon(
                  Icons.open_in_browser), // Add an import icon button
              onPressed: () {
                // Show a popup menu to choose and import a lineup from a past game.
                _showImportPopup(team1Players, addedPlayersTeam1);
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Scroll down logic
                scrollControllerGame1.animateTo(
                  scrollControllerGame1.offset -
                      300, // Adjust this value as needed
                  curve: Curves.linear,
                  duration:
                      Duration(milliseconds: 5), // Adjust this value as needed
                );
              },
              child: Icon(Icons.arrow_upward),
            ),
            Expanded(
              child: SizedBox(
                width: teamsColWidth, // Set the desired width here
                child: SingleChildScrollView(
                  controller: scrollControllerGame1, // Add a ScrollController

                  child: Column(
                    children: <Widget>[
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: team1Players.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: () {
                              // Double-clicked, remove the player
                              setState(() {
                                addedPlayersTeam1
                                    .remove(team1Players[index].playerid);
                                team1Players[index].playerid = 0;
                                team1Players[index].name = "-";
                              });
                            },
                            onTap: () {
                              if (selectedPlayerPK == -1) {
                                if (selectedCardIndexTeam1 == -1) {
                                  setState(() {
                                    selectedCardIndexTeam1 = index;
                                  });
                                } else if (selectedCardIndexTeam1 == index) {
                                  setState(() {
                                    selectedCardIndexTeam1 =
                                        -1; // Deselect the card
                                  });
                                } else {
                                  // Swap name and playerid between the selected and clicked cards
                                  final tempName =
                                      team1Players[selectedCardIndexTeam1].name;
                                  final tempPlayerID =
                                      team1Players[selectedCardIndexTeam1]
                                          .playerid;

                                  setState(() {
                                    team1Players[selectedCardIndexTeam1].name =
                                        team1Players[index].name;
                                    team1Players[selectedCardIndexTeam1]
                                            .playerid =
                                        team1Players[index].playerid;
                                    team1Players[index].name = tempName;
                                    team1Players[index].playerid = tempPlayerID;
                                  });
                                  setState(() {
                                    selectedCardIndexTeam1 = -1;
                                  });
                                  // Deselect after the swap
                                }
                              } else {
                                final playerPK = selectedPlayerPK;
                                if (!addedPlayersTeam1.contains(playerPK)) {
                                  setState(() {
                                    addedPlayersTeam1
                                        .remove(team1Players[index].playerid);
                                    team1Players[index].playerid = playerPK;
                                    String nameFull = widget.availablePlayers
                                        .firstWhere(
                                            (player) => player.pk == playerPK)
                                        .name;
                                    team1Players[index].name = nameFull;
                                    addedPlayersTeam1.add(playerPK);
                                  });
                                  selectedPlayerPK = -1;
                                }
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 4,
                                  color: selectedCardIndexTeam1 == index
                                      ? Colors
                                          .red // Add a red border if selected
                                      : Colors
                                          .transparent, // No border if not selected
                                ),
                                color: yourOriginalPlayerList.any((player) =>
                                            player.pk ==
                                            team1Players[index].playerid) ||
                                        team1Players[index].playerid == 0
                                    ? Colors.white.withOpacity(
                                        0.3) // Player is in availablePlayersFiltered
                                    : Colors.red.withOpacity(0.3),
                              ),
                              child: Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "${team1Players[index].posid + 1} ${team1Players[index].name}",
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (team1Players[index].playerid != 0)
                                            returnStateIcon(
                                                widget.availablePlayers
                                                    .firstWhere((player) =>
                                                        player.pk ==
                                                        team1Players[index]
                                                            .playerid)
                                                    .state,
                                                true),
                                          if (team1Players[index].playerid != 0)
                                            Icon(
                                              widget.availablePlayers
                                                          .firstWhere(
                                                              (player) =>
                                                                  player.pk ==
                                                                  team1Players[
                                                                          index]
                                                                      .playerid)
                                                          .playerProfile
                                                          .classification
                                                          ?.icon !=
                                                      null
                                                  ? IconData(
                                                      int.parse(
                                                          '0x${widget.availablePlayers.firstWhere((player) => player.pk == team1Players[index].playerid).playerProfile.classification!.icon}'),
                                                      fontFamily:
                                                          'MaterialIcons',
                                                    )
                                                  : Icons.highlight_off,
                                              size: 15,
                                            ),
                                          if (team1Players[index].playerid != 0)
                                            Text("${widget.availablePlayers
                                                    .firstWhere((player) =>
                                                        player.pk ==
                                                        team1Players[index]
                                                            .playerid)
                                                    .attendance_percentage}%")
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Scroll down logic
                scrollControllerGame1.animateTo(
                  scrollControllerGame1.offset +
                      300, // Adjust this value as needed
                  curve: Curves.linear,
                  duration:
                      Duration(milliseconds: 5), // Adjust this value as needed
                );
              },
              child: Icon(Icons.arrow_downward),
            ),
          ]),
          if (team2id != "")
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(team2Title, textScaleFactor: 0.8),
                IconButton(
                  icon: const Icon(
                      Icons.open_in_browser), // Add an import icon button
                  onPressed: () {
                    // Show a popup menu to choose and import a lineup from a past game.
                    _showImportPopup(team2Players, addedPlayersTeam2);
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    // Scroll up logic
                    scrollControllerGame2.animateTo(
                      scrollControllerGame2.offset -
                          300, // Adjust this value as needed
                      curve: Curves.linear,
                      duration: Duration(
                          milliseconds: 5), // Adjust this value as needed
                    );
                  },
                  child: Icon(Icons.arrow_upward),
                ),
                Expanded(
                  child: SizedBox(
                    width: teamsColWidth, // Set the desired width here
                    child: SingleChildScrollView(
                      controller:
                          scrollControllerGame2, // Add a ScrollController

                      child: Column(
                        children: <Widget>[
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: team2Players.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onDoubleTap: () {
                                  // Double-clicked, remove the player
                                  setState(() {
                                    addedPlayersTeam2
                                        .remove(team2Players[index].playerid);
                                    team2Players[index].playerid = 0;
                                    team2Players[index].name = "-";
                                  });
                                },
                                onTap: () {
                                  if (selectedPlayerPK == -1) {
                                    if (selectedCardIndexTeam2 == -1) {
                                      setState(() {
                                        selectedCardIndexTeam2 = index;
                                      });
                                    } else if (selectedCardIndexTeam2 ==
                                        index) {
                                      setState(() {
                                        selectedCardIndexTeam2 =
                                            -1; // Deselect the card
                                      });
                                    } else {
                                      // Swap name and playerid between the selected and clicked cards
                                      final tempName =
                                          team2Players[selectedCardIndexTeam2]
                                              .name;
                                      final tempPlayerID =
                                          team2Players[selectedCardIndexTeam2]
                                              .playerid;

                                      setState(() {
                                        team2Players[selectedCardIndexTeam2]
                                            .name = team2Players[index].name;
                                        team2Players[selectedCardIndexTeam2]
                                                .playerid =
                                            team2Players[index].playerid;
                                        team2Players[index].name = tempName;
                                        team2Players[index].playerid =
                                            tempPlayerID;
                                      });
                                      setState(() {
                                        selectedCardIndexTeam2 = -1;
                                      });
                                      // Deselect after the swap
                                    }
                                  } else {
                                    final playerPK2 = selectedPlayerPK;
                                    if (!addedPlayersTeam2
                                        .contains(playerPK2)) {
                                      setState(() {
                                        addedPlayersTeam2.remove(
                                            team2Players[index].playerid);
                                        team2Players[index].playerid =
                                            playerPK2;
                                        String nameFull = widget
                                            .availablePlayers
                                            .firstWhere((player) =>
                                                player.pk == playerPK2)
                                            .name;
                                        team2Players[index].name = nameFull;
                                        addedPlayersTeam2.add(playerPK2);
                                      });
                                      selectedPlayerPK = -1;
                                    }
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 4,
                                      color: selectedCardIndexTeam2 == index
                                          ? Colors
                                              .red // Add a red border if selected
                                          : Colors
                                              .transparent, // No border if not selected
                                    ),
                                    color: yourOriginalPlayerList.any(
                                                (player) =>
                                                    player.pk ==
                                                    team2Players[index]
                                                        .playerid) ||
                                            team2Players[index].playerid == 0
                                        ? Colors.white.withOpacity(
                                            0.3) // Player is in availablePlayersFiltered
                                        : Colors.red.withOpacity(0.3),
                                  ), // Player is not in availablePlayersFiltered
                                  child: Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "${team2Players[index].posid + 1} ${team2Players[index].name}",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              if (team2Players[index]
                                                      .playerid !=
                                                  0)
                                                returnStateIcon(
                                                    widget.availablePlayers
                                                        .firstWhere((player) =>
                                                            player.pk ==
                                                            team2Players[index]
                                                                .playerid)
                                                        .state,
                                                    true),
                                              if (team2Players[index]
                                                      .playerid !=
                                                  0)
                                                Icon(
                                                  widget.availablePlayers
                                                              .firstWhere((player) =>
                                                                  player.pk ==
                                                                  team2Players[
                                                                          index]
                                                                      .playerid)
                                                              .playerProfile
                                                              .classification
                                                              ?.icon !=
                                                          null
                                                      ? IconData(
                                                          int.parse(
                                                              '0x${widget.availablePlayers.firstWhere((player) => player.pk == team2Players[index].playerid).playerProfile.classification!.icon}'),
                                                          fontFamily:
                                                              'MaterialIcons',
                                                        )
                                                      : Icons.highlight_off,
                                                  size: 15,
                                                ),
                                              if (team2Players[index]
                                                      .playerid !=
                                                  0)
                                                Text("${widget.availablePlayers
                                                        .firstWhere((player) =>
                                                            player.pk ==
                                                            team2Players[index]
                                                                .playerid)
                                                        .attendance_percentage}%")
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Scroll down logic
                    scrollControllerGame2.animateTo(
                      scrollControllerGame2.offset +
                          300, // Adjust this value as needed
                      curve: Curves.linear,
                      duration: Duration(
                          milliseconds: 5), // Adjust this value as needed
                    );
                  },
                  child: Icon(Icons.arrow_downward),
                ),
              ],
            )
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Line up'),
              pw.Divider(),
              pw.SizedBox(height: 40),
              pw.Text(team1Title),
              pw.Divider(),
              for (var index = 0; index < team1Players.length; index++)
                pw.Column(
                  children: [
                    pw.Container(
                      color:
                          index % 2 == 0 ? PdfColors.grey200 : PdfColors.white,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            (team1Players[index].posid + 1).toString(),
                            textAlign: pw.TextAlign.left,
                          ),
                          pw.SizedBox(width: 30),
                          pw.Text(
                            team1Players[index].name,
                            textAlign: pw.TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
            ],
          );
        },
      ),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Line up'),
              pw.Divider(),
              pw.SizedBox(height: 40),
              pw.Text(team2Title),
              pw.Divider(),
              for (var index = 0; index < team2Players.length; index++)
                pw.Column(
                  children: [
                    pw.Container(
                      color:
                          index % 2 == 0 ? PdfColors.grey200 : PdfColors.white,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            (team1Players[index].posid + 1).toString(),
                            textAlign: pw.TextAlign.left,
                          ),
                          pw.SizedBox(width: 30),
                          pw.Text(
                            team2Players[index].name,
                            textAlign: pw.TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    // final file = File('/home/ctrl/training_report.pdf');
    // await file.writeAsBytes(await pdf.save());

    // Open the PDF directly without saving to disk
    saveAndDownloadFile("lineup.pdf", pdfBytes);
  }

  Future<void> saveAndDownloadFile(String fileName, Uint8List content) async {
    try {
      // Handle file download for web platforms
      final blob = uh.Blob([Uint8List.fromList(content)]);
      final url = uh.Url.createObjectUrlFromBlob(blob);
      final anchor = uh.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      uh.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error generating file: $e');
      Navigator.of(context).pop(); // Close the generation status dialog
    }
  }

  Future<void> _publish(String gameid) async {
    final response = await http.patch(
      Uri.parse('${globals.URL_PREFIX}/api/game/$gameid/'),
      headers: {'Authorization': 'Token ${globals.token}'},
      body: {'lineup_published': 'true'},
    );
  }

  Future<void> _save(List<LineUpEditorModel> playerslist, String gameid) async {
    await Future.forEach(playerslist, (LineUpEditorModel player) async {
      if (player.fieldid != null) {
        final response = await http.patch(
          Uri.parse('${globals.URL_PREFIX}/api/lineuppos/${player.fieldid}/'),
          headers: {'Authorization': 'Token ${globals.token}'},
          body: {
            if (player.playerid != 0)
              'player_id': player.playerid.toString()
            else
              'player_id': "",
          },
        );

        if (response.statusCode == 200) {
          // Handle success as needed.
          print('Updated training part with id: ${player.fieldid}');
        } else {
          // Handle error if necessary.
          print('API Error: ${response.statusCode}');
        }
      } else {
        final response = await http.post(
          Uri.parse('${globals.URL_PREFIX}/api/lineuppos/'),
          headers: {'Authorization': 'Token ${globals.token}'},
          body: {
            if (player.playerid != 0)
              'player_id': player.playerid.toString()
            else
              'player_id': "",
            'position': player.posid.toString(),
            'game_id': gameid,
          },
        );

        if (response.statusCode == 201) {
          // Handle success as needed.
          print('Created a new lineuppos');
          // Update the trainingPart with the newly created primary key (pk).
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          //trainingPart.id = responseData['id'];
        } else {
          // Handle error if necessary.
          print('API Error: ${response.statusCode}');
        }
      }
    });
  }

  Future<List<GameModel>> loadPastGames() async {
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/games_past/filter?club=${globals.clubId}&season=${globals.seasonID}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    String responseBody = utf8.decode(response.bodyBytes);
    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
    List<GameModel> games = items.map<GameModel>((json) {
      return GameModel.fromJson(json);
    }).toList();

    return games;
  }

  void _showImportPopup(
      List<LineUpEditorModel> index, Set<int> addedPlayers) async {
    List<GameModel> pastGames = await loadPastGames();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose a past game lineup'),
          content: SingleChildScrollView(
            child: Column(
              children: pastGames.map((game) {
                return ListTile(
                  title: Text('${game.home} - ${game.away}'),
                  onTap: () async {
                    List<LineUpPosModel> lineup = await getLineUp(game.pk);
                    for (var player in lineup) {
                      if (player.player != null) {
                        setState(() {
                          addedPlayers.remove(index[player.position].playerid);

                          index[player.position].name = player.player!.name;
                          index[player.position].playerid = player.player!.pk;
                          addedPlayers.add(player.player!.pk);
                        });
                      }
                    }

                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _buildPositionDropdownItems() {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem<String>(
        value: "All",
        child: Text("All"),
      )
    ];
    // Add "All" as the first item
    items.addAll(positionOptions.map((position) {
      return DropdownMenuItem<String>(
        value: position.position,
        child: Text(position.position),
      );
    }));
    return items;
  }

  void filterPlayersByPosition() {
    if (selectedPosition == "All") {
      // Show all players
      setState(() {
        availablePlayersFiltered = yourOriginalPlayerList;
      });
    } else {
      // Filter players based on the selected position
      setState(() {
        availablePlayersFiltered = yourOriginalPlayerList.where((player) {
          // Replace 'positionField' with the actual field in your UserProfileModel
          return player.playerProfile.positions!
              .any((position) => position.position == selectedPosition);
        }).toList();
      });
    }
  }
}
