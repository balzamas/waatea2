import 'dart:typed_data';

import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:csv/csv.dart'; // Import the csv package
import '../models/availability_model.dart';
import '../models/showavailabilitydetail_model.dart';
// ignore: depend_on_referenced_packages
import '../widgets/showavailabilitydetail_row.dart';
import 'package:universal_html/html.dart' as uh;

enum SortOption { state, updated, name }

enum FileGenerationStatus { idle, generating, complete, error }

class ShowAvailabilityDetail extends StatefulWidget {
  late final String gameid;
  late final String game;
  late final String gameDate;
  late final int dayofyear;
  late final String season;
  late final int isAvailable;
  late final int isNotAvailable;
  late final int isMaybe;
  late final int isNotSet;

  ShowAvailabilityDetail(
      this.gameid,
      this.game,
      this.gameDate,
      this.dayofyear,
      this.season,
      this.isAvailable,
      this.isNotAvailable,
      this.isMaybe,
      this.isNotSet);
  @override
  ShowAvailabilityDetailState createState() => ShowAvailabilityDetailState();
}

class ShowAvailabilityDetailState extends State<ShowAvailabilityDetail> {
  late Future<List<ShowAvailabilityDetailModel>> games;
  final availabilityListKey = GlobalKey<ShowAvailabilityDetailState>();
  SortOption currentSortOption = SortOption.name;
  bool showOnlyAvailableMaybe = false;
  bool sortByNameAscending = true;
  FileGenerationStatus generationStatus = FileGenerationStatus.idle;

  @override
  void initState() {
    super.initState();
    games = getPlayerList();
  }

  Future<void> saveAndDownloadFile(String fileName, String content) async {
    try {
      // Handle file download for web platforms
      final blob = uh.Blob([Uint8List.fromList(content.codeUnits)]);
      final url = uh.Url.createObjectUrlFromBlob(blob);
      final anchor = uh.AnchorElement(href: url)
        ..setAttribute('download', '$fileName')
        ..click();
      uh.Url.revokeObjectUrl(url);
      setState(() {
        generationStatus = FileGenerationStatus.complete;
      });
    } catch (e) {
      print('Error generating file: $e');
      Navigator.of(context).pop(); // Close the generation status dialog
      setState(() {
        generationStatus = FileGenerationStatus.error;
      });
    }
  }

  Future<void> saveCSVToFile(List<ShowAvailabilityDetailModel> players) async {
    setState(() {
      generationStatus = FileGenerationStatus.generating;
    });
    List<List<dynamic>> csvData = [
      [
        'Name',
        'Assessment',
        'Classification',
        'Availability',
        'Abonnement',
        'Training l10',
        'Training l4',
        'Training Tot'
      ]
    ];

    for (var player in players) {
      var availabilityText = '';
      switch (player.state) {
        case 0:
          availabilityText = 'Not Set';
          break;
        case 1:
          availabilityText = 'Available';
          break;
        case 2:
          availabilityText = 'Maybe';
          break;
        case 3:
          availabilityText = 'Not Available';
          break;
      }

      int attended10 = 0;
      int attended4 = 0;
      int attended_tot = 0;
      int training_count = 0;

      List<AttendedViewModel> trainings10 = [];
      final response = await http.get(
          Uri.parse(
              '${globals.URL_PREFIX}/api/training-attendance?season=${globals.seasonID}&club=${globals.clubId}&user_id=${player.pk}'),
          headers: {'Authorization': 'Token ${globals.token}'});
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        trainings10 = data
            .map((item) => AttendedViewModel(
                  date: item['date'],
                  attended: item['attended'],
                ))
            .toList();
        for (AttendedViewModel training in trainings10) {
          training_count = training_count + 1;
          if (training.attended) {
            attended_tot = attended_tot + 1;
            if (training_count < 11) {
              attended10 = attended10 + 1;
              if (training_count < 5) {
                attended4 = attended4 + 1;
              }
            }
          }
        }
      }

      csvData.add([
        player.name,
        player.playerProfile.assessment?.name ?? 'Not Set',
        player.playerProfile.classification?.name ?? 'Not Set',
        availabilityText,
        player.playerProfile.abonnement?.name ?? 'Not Set',
        attended10,
        attended4,
        attended_tot
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);

    saveAndDownloadFile('${widget.game}.csv', csv);
  }

  Future<List<ShowAvailabilityDetailModel>> getPlayerList() async {
    //Get players
    final responsePlayer = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}&is_playing=True"),
        headers: {'Authorization': 'Token ${globals.token}'});

    String responseBody = utf8.decode(responsePlayer.bodyBytes);
    final itemsPlayers = json.decode(responseBody).cast<Map<String, dynamic>>();
    List<ShowAvailabilityDetailModel> players =
        itemsPlayers.map<ShowAvailabilityDetailModel>((json) {
      return ShowAvailabilityDetailModel.fromJson(json);
    }).toList();

    final responseAvail = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/availabilities/filter?dayofyear=${widget.dayofyear}&season=${widget.season}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    if (responseAvail.statusCode == 200) {
      final itemsAvailability =
          json.decode(responseAvail.body).cast<Map<String, dynamic>>();
      List<AvailabilityModel> availabilities =
          itemsAvailability.map<AvailabilityModel>((json) {
        return AvailabilityModel.fromJson(json);
      }).toList();

      //Get availabilities
      for (var i = 0; i < players.length; i++) {
        var myListFiltered =
            availabilities.where((e) => e.player == players[i].pk);
        if (myListFiltered.length == 1) {
          players[i].state = myListFiltered.first.state;
          if (myListFiltered.first.updated != "") {
            DateTime updated =
                DateTime.parse(myListFiltered.first.updated).toLocal();
            players[i].updated =
                '${updated.day}.${updated.month}.${updated.year} ${updated.hour}:${updated.minute}';
          }
        } else if (myListFiltered.length > 1) {
          print("Error! Too many availabilities");
        }
      }
    }

    return players;
  }

  void onSortOptionChanged(SortOption option) {
    setState(() {
      currentSortOption = option;
    });
  }

  void onNameSortChanged() {
    setState(() {
      sortByNameAscending = !sortByNameAscending;
    });
  }

  void onFilterChanged(bool newValue) {
    setState(() {
      showOnlyAvailableMaybe = newValue;
    });
  }

  void showGenerationStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: const Text('File Generation Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (generationStatus == FileGenerationStatus.generating)
                    const Text('Generating...'),
                  if (generationStatus == FileGenerationStatus.complete)
                    const Text('File generated successfully.'),
                  if (generationStatus == FileGenerationStatus.error)
                    const Text('Error generating file.'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: Text(
            "${widget.game} // ${DateTime.parse(widget.gameDate).day}.${DateTime.parse(widget.gameDate).month}.${DateTime.parse(widget.gameDate).year}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AlertDialog(
                    title: Text('Generating File...'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.black),
                        Text('Please wait while the file is being generated.'),
                      ],
                    ),
                  );
                },
              );
              try {
                setState(() {
                  generationStatus = FileGenerationStatus.generating;
                });

                var players = await games; // Await the completion of the Future
                await saveCSVToFile(players);
                Navigator.of(context).pop();
                setState(() {
                  generationStatus = FileGenerationStatus.complete;
                });
              } catch (e) {
                print('Error generating file: $e');
                setState(() {
                  generationStatus = FileGenerationStatus.error;
                });
              }

              // Show the dialog after the file generation is complete
              showGenerationStatusDialog(context);
            },
          ),
          PopupMenuButton<SortOption>(
            onSelected: onSortOptionChanged,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: SortOption.state,
                child: Text('Sort by State'),
              ),
              const PopupMenuItem(
                value: SortOption.updated,
                child: Text('Sort by Updated'),
              ),
              const PopupMenuItem(
                value: SortOption.name,
                child: Text('Sort by Name'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(showOnlyAvailableMaybe
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            onPressed: () {
              onFilterChanged(!showOnlyAvailableMaybe);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.green,
                      radius: 20.0,
                      child: Text(widget.isAvailable.toString(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.orange,
                      radius: 20.0,
                      child: Text(widget.isMaybe.toString(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.red,
                      radius: 20.0,
                      child: Text(widget.isNotAvailable.toString(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.grey,
                      radius: 20.0,
                      child: Text(widget.isNotSet.toString(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )),
          Expanded(
            child: FutureBuilder<List<ShowAvailabilityDetailModel>>(
              future: games,
              builder: (BuildContext context,
                  AsyncSnapshot<List<ShowAvailabilityDetailModel>> snapshot) {
                if (!snapshot.hasData)
                  return const CircularProgressIndicator(color: Colors.black);

                // Apply filtering
                var filteredPlayers = snapshot.data!.where((player) {
                  if (showOnlyAvailableMaybe) {
                    return player.state == 2 || player.state == 3;
                  }
                  return true;
                }).toList();

                // Apply sorting
                filteredPlayers.sort((a, b) {
                  switch (currentSortOption) {
                    case SortOption.state:
                      return b.state.compareTo(a.state);
                    case SortOption.updated:
                      return b.updated.compareTo(a.updated);
                    case SortOption.name: // Added name sorting
                      return sortByNameAscending
                          ? a.name.compareTo(b.name)
                          : b.name.compareTo(a.name);
                  }
                });

                return ListView.builder(
                  itemCount: filteredPlayers.length,
                  itemBuilder: (BuildContext context, int index) {
                    var data = filteredPlayers[index];

                    return ShowAvailabilityDetailRow(
                        name: data.name,
                        phonenumber: data.mobilephone,
                        state: data.state,
                        assessment: data.playerProfile.assessment,
                        updated: data.updated,
                        player: data.playerProfile,
                        attendancePercentage: data.attendance_percentage,
                        game:
                            "${widget.game} // ${DateTime.parse(widget.gameDate).day}.${DateTime.parse(widget.gameDate).month}.${DateTime.parse(widget.gameDate).year}");
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
