import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/column2player_model.dart';
import 'package:waatea2_client/models/showavailabilitydetail_model.dart';
import 'package:uuid/uuid.dart';

import 'package:pdf/widgets.dart' as pw;

import 'dart:io';
import 'package:universal_html/html.dart' as uh;

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
      posid: index,
      playerid: 0,
      name: "-",
      fieldid: Uuid(),
    ),
  );

  List<Column2PlayerModel> column3Players = List.generate(
    23,
    (index) => Column2PlayerModel(
      posid: index,
      playerid: 0,
      name: "-",
      fieldid: Uuid(),
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
                  Text("Team 1"),
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
                                column2Players[index] = Column2PlayerModel(
                                  posid: index,
                                  playerid: playerPK,
                                  name: availablePlayersFiltered
                                      .firstWhere(
                                          (player) => player.pk == playerPK)
                                      .name,
                                  fieldid: Uuid(),
                                );
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text("Team 2"),
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
                                column3Players[index] = Column2PlayerModel(
                                  posid: index,
                                  playerid: playerPK2,
                                  name: availablePlayersFiltered
                                      .firstWhere(
                                          (player) => player.pk == playerPK2)
                                      .name,
                                  fieldid: Uuid(),
                                );
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

    final file = File('/home/ctrl/training_report.pdf');
    await file.writeAsBytes(await pdf.save());

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
}
