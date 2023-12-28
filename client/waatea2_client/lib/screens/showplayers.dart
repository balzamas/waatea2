import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/availability_model.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/showplayerdetail.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:universal_html/html.dart' as uh;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/game_model.dart';
import '../models/showavailabilitydetail_model.dart';

enum FileGenerationStatus { idle, generating, complete, error }

class ShowPlayers extends StatefulWidget {
  ShowPlayers();

  @override
  _ShowPlayersState createState() => _ShowPlayersState();
}

class _ShowPlayersState extends State<ShowPlayers> {
  List<UserModel> users = [];
  bool showOnlyActive = false;
  FileGenerationStatus generationStatus = FileGenerationStatus.idle;

  Future<void> saveAndDownloadFile(String fileName, String content) async {
    try {
      // File Download Linux
      // final directory = await getApplicationDocumentsDirectory();
      // final filePath = '${directory.path}/$fileName';
      // final file = File(filePath);
      // await file.writeAsString(content);

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

  Future<void> saveCSVToFile(List<UserModel> players) async {
    setState(() {
      generationStatus = FileGenerationStatus.generating;
    });

    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/games_past/filter?club=${globals.clubId}&season=${globals.seasonID}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    String responseBody = utf8.decode(response.bodyBytes);
    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
    List<GameModel> games = items.map<GameModel>((json) {
      return GameModel.fromJson(json);
    }).toList();

    List<List<dynamic>> csvData = [
      [
        'Name',
        'Assessment',
        'Classification',
        'Abonnement',
        'Training l10',
        'Training l4',
        'Training Tot',
        'Games Avail',
        'Games Maybe',
        'Games Unavail',
        'Games Notset',
        'Caps'
      ]
    ];

    for (var player in players) {
      int available = 0;
      int maybe = 0;
      int notavailable = 0;
      int notset = 0;

      final responseAvail = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/availabilities/filter?player=${player.pk}&season=${globals.seasonID}"),
          headers: {'Authorization': 'Token ${globals.token}'});

      if (responseAvail.statusCode == 200) {
        final items =
            json.decode(responseAvail.body).cast<Map<String, dynamic>>();
        List<AvailabilityModel> availabilities =
            items.map<AvailabilityModel>((json) {
          return AvailabilityModel.fromJson(json);
        }).toList();

        if (availabilities.isNotEmpty) {
          for (AvailabilityModel availability in availabilities) {
            if (games.any((obj) => obj.dayofyear == availability.dayofyear)) {
              if (availability.state == 1) {
                notavailable = notavailable + 1;
              } else if (availability.state == 2) {
                maybe = maybe + 1;
              } else if (availability.state == 3) {
                available = available + 1;
              }
            }
          }
        }
      }

      int uniqueCount = games.map((obj) => obj.dayofyear).toSet().length;
      notset = uniqueCount - (available + notavailable + maybe);

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
        player.profile?.assessment?.name ?? 'Not Set',
        player.profile?.classification?.name ?? 'Not Set',
        player.profile?.abonnement?.name ?? 'Not Set',
        attended10,
        attended4,
        attended_tot,
        available,
        maybe,
        notavailable,
        notset,
        player.caps
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);

    saveAndDownloadFile('players.csv', csv);
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
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = jsonDecode(responseBody);
      setState(() {
        users = data.map((item) => UserModel.fromJson(item)).toList();
      });
    }
  }

  List<UserModel> getFilteredUsers() {
    if (showOnlyActive) {
      return users.where((user) => user.profile.isPlaying).toList();
    } else {
      return users;
    }
  }

  void onFilterChanged(bool newValue) {
    setState(() {
      showOnlyActive = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
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

                var players = await users; // Await the completion of the Future
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
          IconButton(
            icon: Icon(showOnlyActive
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            onPressed: () {
              onFilterChanged(!showOnlyActive);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: getFilteredUsers().length,
        itemBuilder: (context, index) {
          final user = getFilteredUsers()[index];
          Color playerColor = Colors.black;
          if (!user.profile.isPlaying) {
            playerColor = Colors.red;
          }

          return ListTile(
            leading: RandomAvatar(user.name, height: 40, width: 40),
            title: Text(
              user.name,
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(fontSizeFactor: 1, color: playerColor),
            ),
            // subtitle: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Container(
            //       width: 500, // Replace with your desired width
            //       height: 40, // Replace with your desired height
            //       child:
            //           ShowPlayerAttendance(user.pk, 6, MainAxisAlignment.start),
            //     ),
            //   ],
            // ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.profile.classification != null &&
                    user.profile.classification?.icon != null)
                  Padding(
                      padding: EdgeInsets.only(
                          right: 8.0), // Adjust spacing as needed
                      child: Icon(
                        IconData(
                            int.parse('0x${user.profile.classification!.icon}'),
                            fontFamily: 'MaterialIcons'),
                      )),
                if (user.profile.assessment != null &&
                    user.profile.assessment?.icon != null)
                  Padding(
                      padding: EdgeInsets.only(
                          right: 8.0), // Adjust spacing as needed
                      child: Icon(
                        IconData(
                            int.parse('0x${user.profile.assessment!.icon}'),
                            fontFamily: 'MaterialIcons'),
                      )),
                const SizedBox(width: 10),
                Text(
                  user.attendancePercentage.toString() + "%",
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1, color: playerColor),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShowPlayerDetail(
                    user: user,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
