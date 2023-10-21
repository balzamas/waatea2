import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/column2player_model.dart';
import 'package:waatea2_client/models/game_model.dart';
import 'package:waatea2_client/models/lineuppos_model.dart';
import 'package:waatea2_client/models/showavailability_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/screens/lineupshow.dart';
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:pdf/widgets.dart' as pw;

import 'dart:io';
import 'package:universal_html/html.dart' as uh;

class YourScreen extends StatefulWidget {
  final List<ShowAvailabilityDetailModel> availablePlayers;
  final int dayoftheyear;
  final String season;

  YourScreen(
      {required this.availablePlayers,
      required this.dayoftheyear,
      required this.season});

  @override
  _YourScreenState createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  late Future<List<GameModel>> games;

  List<Column2PlayerModel> column2Players = List.generate(
    23,
    (index) => Column2PlayerModel(
      posid: index,
      playerid: 0,
      name: "-",
      fieldid: null,
    ),
  );

  List<Column2PlayerModel> column3Players = List.generate(
    23,
    (index) => Column2PlayerModel(
      posid: index,
      playerid: 0,
      name: "-",
      fieldid: null,
    ),
  );

  int selectedPlayerPK = -1; // Track the selected player in the first column
  Set<int> addedPlayerPKs =
      Set(); // Track players already added to the second column
  int selectedCardIndex =
      -1; // Track the index of the selected card in the second column
  Set<int> addedPlayerPKs2 =
      Set(); // Track players already added to the third column
  int selectedCardIndex2 =
      -1; // Track the index of the selected card in the third column
  String team1Title = ""; // Initialize with an empty string
  String team1id = ""; // Initialize with an empty string
  String team2Title = ""; // Initialize with an empty string
  String team2id = ""; // Initialize with an empty string

  @override
  void initState() {
    super.initState();
    games = getGameList(widget.season, widget.dayoftheyear);
    //This is ugly bullshit
    games.then((gameList) {
      if (gameList.isNotEmpty) {
        setState(() {
          team1Title =
              "${gameList[0].home} - ${gameList[0].away}"; // Set the title
          team1id = gameList[0].pk;
        });
        Future<List<LineUpPosModel>> playersTeam1 = getLineUp(team1id);
        playersTeam1.then((player1List) {
          player1List.forEach((player) {
            print(".......");
            print(player.id);
            setState(() {
              if (player.player != null) {
                column2Players[player.position].name = player.player!.name;
                column2Players[player.position].playerid = player.player!.pk;
                addedPlayerPKs.add(player.player!.pk);
              }
              column2Players[player.position].fieldid = player.id;
            });
          });
        });
      }
      if (gameList.length > 1) {
        setState(() {
          team2Title =
              "${gameList[1].home} - ${gameList[1].away}"; // Set the title

          team2id = gameList[1].pk;
        });
        Future<List<LineUpPosModel>> playersTeam2 = getLineUp(team2id);
        playersTeam2.then((player2List) {
          player2List.forEach((player) {
            setState(() {
              if (player.player != null) {
                column3Players[player.position].name = player.player!.name;
                column3Players[player.position].playerid = player.player!.pk;
                addedPlayerPKs2.add(player.player!.pk);
              }
              column3Players[player.position].fieldid = player.id;
            });
          });
        });
      }
    });
    //Load lineups
  }

  @override
  Widget build(BuildContext context) {
    final List<ShowAvailabilityDetailModel> availablePlayersFiltered = widget
        .availablePlayers
        .where((player) => player.state == 2 || player.state == 3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Player Selection Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.publish),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _publish(team1id);
              _publish(team2id);
            },
          ),
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: () async {
              final team1Lineup =
                  await getLineUp(team1id); // Load the lineup for team 1
              final team2Lineup =
                  await getLineUp(team2id); // Load the lineup for team 2

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LineupScreen(
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
            icon: Icon(Icons.save),
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
                _save(column2Players, team1id),
                if (team2id != "") _save(column3Players, team2id),
              ]);
              Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _generatePDF();
            },
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
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
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selectedPlayerPK ==
                                          availablePlayersFiltered[i].pk) {
                                        selectedPlayerPK =
                                            -1; // Unselect if already selected
                                      } else {
                                        selectedPlayerPK =
                                            availablePlayersFiltered[i].pk;
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 4,
                                        color: selectedPlayerPK ==
                                                availablePlayersFiltered[i].pk
                                            ? Colors
                                                .red // Add a red border if selected
                                            : Colors
                                                .transparent, // No border if not selected
                                      ),
                                    ),
                                    child: Card(
                                      elevation: 2,
                                      color: addedPlayerPKs.contains(
                                                  availablePlayersFiltered[i]
                                                      .pk) &&
                                              addedPlayerPKs2.contains(
                                                  availablePlayersFiltered[i]
                                                      .pk)
                                          ? Colors
                                              .grey // Player is in both columns
                                          : addedPlayerPKs.contains(
                                                  availablePlayersFiltered[i]
                                                      .pk)
                                              ? Colors.green.withOpacity(
                                                  0.3) // Player is only in team 1
                                              : addedPlayerPKs2.contains(
                                                      availablePlayersFiltered[i]
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
                                                    "${availablePlayersFiltered[i].attendance_percentage}%"),
                                              ],
                                            ),
                                          ],
                                        ),
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
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(team1Title),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: column2Players.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onDoubleTap: () {
                          // Double-clicked, remove the player
                          setState(() {
                            addedPlayerPKs
                                .remove(column2Players[index].playerid);
                            column2Players[index].playerid = 0;
                            column2Players[index].name = "-";
                          });
                        },
                        onTap: () {
                          if (selectedPlayerPK == -1) {
                            if (selectedCardIndex == -1) {
                              setState(() {
                                selectedCardIndex = index;
                              });
                            } else if (selectedCardIndex == index) {
                              setState(() {
                                selectedCardIndex = -1; // Deselect the card
                              });
                            } else {
                              // Swap name and playerid between the selected and clicked cards
                              final tempName =
                                  column2Players[selectedCardIndex].name;
                              final tempPlayerID =
                                  column2Players[selectedCardIndex].playerid;

                              setState(() {
                                column2Players[selectedCardIndex].name =
                                    column2Players[index].name;
                                column2Players[selectedCardIndex].playerid =
                                    column2Players[index].playerid;
                                column2Players[index].name = tempName;
                                column2Players[index].playerid = tempPlayerID;
                              });
                              setState(() {
                                selectedCardIndex = -1;
                              });
                              // Deselect after the swap
                            }
                          } else {
                            final playerPK = selectedPlayerPK;
                            if (!addedPlayerPKs.contains(playerPK)) {
                              setState(() {
                                addedPlayerPKs
                                    .remove(column2Players[index].playerid);
                                column2Players[index].playerid = playerPK;
                                column2Players[index].name =
                                    availablePlayersFiltered
                                        .firstWhere(
                                            (player) => player.pk == playerPK)
                                        .name;
                                addedPlayerPKs.add(playerPK);
                              });
                              selectedPlayerPK = -1;
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 4,
                              color: selectedCardIndex == index
                                  ? Colors.red // Add a red border if selected
                                  : Colors
                                      .transparent, // No border if not selected
                            ),
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
                                        "${column2Players[index].posid + 1} ${column2Players[index].name}",
                                      ),
                                    ],
                                  ),
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
          if (team2id != "")
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text(team2Title),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: column3Players.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onDoubleTap: () {
                            // Double-clicked, remove the player
                            setState(() {
                              addedPlayerPKs2
                                  .remove(column3Players[index].playerid);
                              column3Players[index].playerid = 0;
                              column3Players[index].name = "-";
                            });
                          },
                          onTap: () {
                            if (selectedPlayerPK == -1) {
                              if (selectedCardIndex2 == -1) {
                                setState(() {
                                  selectedCardIndex2 = index;
                                });
                              } else if (selectedCardIndex2 == index) {
                                setState(() {
                                  selectedCardIndex2 = -1; // Deselect the card
                                });
                              } else {
                                // Swap name and playerid between the selected and clicked cards
                                final tempName =
                                    column3Players[selectedCardIndex2].name;
                                final tempPlayerID =
                                    column3Players[selectedCardIndex2].playerid;

                                setState(() {
                                  column3Players[selectedCardIndex2].name =
                                      column3Players[index].name;
                                  column3Players[selectedCardIndex2].playerid =
                                      column3Players[index].playerid;
                                  column3Players[index].name = tempName;
                                  column3Players[index].playerid = tempPlayerID;
                                });
                                setState(() {
                                  selectedCardIndex2 = -1;
                                });
                                // Deselect after the swap
                              }
                            } else {
                              final playerPK2 = selectedPlayerPK;
                              if (!addedPlayerPKs2.contains(playerPK2)) {
                                setState(() {
                                  addedPlayerPKs2
                                      .remove(column3Players[index].playerid);
                                  column3Players[index].playerid = playerPK2;
                                  column3Players[index].name =
                                      availablePlayersFiltered
                                          .firstWhere((player) =>
                                              player.pk == playerPK2)
                                          .name;
                                  addedPlayerPKs2.add(playerPK2);
                                });
                                selectedPlayerPK = -1;
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 4,
                                color: selectedCardIndex2 == index
                                    ? Colors.red // Add a red border if selected
                                    : Colors
                                        .transparent, // No border if not selected
                              ),
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
                                          "${column3Players[index].posid + 1} ${column3Players[index].name}",
                                        ),
                                      ],
                                    ),
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
              // Training date
              pw.Text('Line up'),

              pw.Divider(),
              pw.SizedBox(height: 40),

              pw.Text('First team'),

              pw.Divider(),

              for (var index = 0; index < column2Players.length; index++)
                if (index < 15 || column2Players[index].playerid != 0)
                  pw.Column(
                    children: [
                      pw.Container(
                        color: index % 2 == 0
                            ? PdfColors.grey200
                            : PdfColors.white,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              (column2Players[index].posid + 1).toString(),
                              textAlign: pw.TextAlign.left,
                            ),
                            pw.SizedBox(width: 30),
                            pw.Text(
                              column2Players[index].name,
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
              // Training date
              pw.Text('Line up'),

              pw.Divider(),
              pw.SizedBox(height: 40),

              pw.Text('Second team'),

              pw.Divider(),

              for (var index = 0; index < column3Players.length; index++)
                if (index < 15 || column3Players[index].playerid != 0)
                  pw.Column(
                    children: [
                      pw.Container(
                        color: index % 2 == 0
                            ? PdfColors.grey200
                            : PdfColors.white,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              (column2Players[index].posid + 1).toString(),
                              textAlign: pw.TextAlign.left,
                            ),
                            pw.SizedBox(width: 30),
                            pw.Text(
                              column3Players[index].name,
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
    saveAndDownloadFile("training.pdf", pdfBytes);
  }

  Future<void> saveAndDownloadFile(String fileName, Uint8List content) async {
    try {
      // Handle file download for web platforms
      final blob = uh.Blob([Uint8List.fromList(content)]);
      final url = uh.Url.createObjectUrlFromBlob(blob);
      final anchor = uh.AnchorElement(href: url)
        ..setAttribute('download', '$fileName')
        ..click();
      uh.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error generating file: $e');
      Navigator.of(context).pop(); // Close the generation status dialog
    }
  }

  Future<void> _publish(String gameid) async {
    final response = await http.patch(
      Uri.parse('${globals.URL_PREFIX}/api/game/${gameid}/'),
      headers: {'Authorization': 'Token ${globals.token}'},
      body: {'lineup_published': 'true'},
    );
  }

  Future<void> _save(
      List<Column2PlayerModel> playerslist, String gameid) async {
    await Future.forEach(playerslist, (Column2PlayerModel player) async {
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
}
