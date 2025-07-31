import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_model.dart';
import '../models/attendance.dart';
import '../globals.dart' as globals;

class PlayerAttendanceStatusScreen extends StatefulWidget {
  final String trainingId;
  const PlayerAttendanceStatusScreen({Key? key, required this.trainingId}) : super(key: key);

  @override
  State<PlayerAttendanceStatusScreen> createState() => _PlayerAttendanceStatusScreenState();
}

class _PlayerAttendanceStatusScreenState extends State<PlayerAttendanceStatusScreen> {
  List<UserModel> players = [];
  Map<String, bool> attendanceMap = {};

  @override
  void initState() {
    super.initState();
    fetchPlayersAndAttendance();
  }

  Future<void> fetchPlayersAndAttendance() async {
    try {
      final responsePlayers = await http.get(
        Uri.parse("${globals.URL_PREFIX}/api/attendingusers/${widget.trainingId}/"),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (responsePlayers.statusCode != 200) {
        print("Fehler beim Laden der Spieler");
        return;
      }

      final playersData = json.decode(responsePlayers.body) as List;
      players = playersData.map((json) => UserModel.fromJson(json)).toList()
  ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final responseAttendance = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/attendances/filter?training=${widget.trainingId}&season=${globals.seasonID}"),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (responseAttendance.statusCode != 200) {
        print("Fehler beim Laden der Anwesenheiten");
        return;
      }

      final attendanceData = json.decode(responseAttendance.body) as List;
      List<AttendanceModel> attendances =
          attendanceData.map((json) => AttendanceModel.fromJson(json)).toList();

      attendanceMap.clear();
      for (var att in attendances) {
        attendanceMap[att.player.toString()] = att.attended;
      }

      setState(() {});
    } catch (e) {
      print("Fehler beim Laden: $e");
    }
  }

  Future<void> _showAddPlayerDialog() async {
    try {
      final response = await http.get(
        Uri.parse("${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}"),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (response.statusCode != 200) {
        print("Fehler beim Laden aller Spieler");
        return;
      }

      final allPlayersData = json.decode(response.body) as List;
      final allPlayers = allPlayersData.map((json) => UserModel.fromJson(json)).toList();

      final existingIds = players.map((p) => p.pk).toSet();
      final missingPlayers = allPlayers.where((p) => !existingIds.contains(p.pk)).toList();
      final searchController = TextEditingController();
      List<UserModel> filteredPlayers = List.from(missingPlayers);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add player to training"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search player',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setDialogState(() {
                        filteredPlayers = missingPlayers
                            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: filteredPlayers.length,
                      itemBuilder: (context, index) {
                        final player = filteredPlayers[index];
                        return ListTile(
                          title: Text(player.name),
                          trailing: const Icon(Icons.add),
                          onTap: () {
                            Navigator.of(context).pop();
                            _addPlayerAttendance(player);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          });
        },
      );
    } catch (e) {
      print("Fehler beim Anzeigen des Dialogs: $e");
    }
  }

  Future<void> _addPlayerAttendance(UserModel player) async {
    try {
      final Map<String, dynamic> body = {
        'attended': true,
        'dayofyear': DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1,
        'player': player.pk,
        'training': widget.trainingId,
        'season': globals.seasonID
      };

      final http.Response response = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/attendance/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchPlayersAndAttendance();
      } else {
        print("Fehler beim Hinzufügen: ${response.body}");
      }
    } catch (e) {
      print("Fehler beim Hinzufügen eines Spielers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Status'),
      ),
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final attended = attendanceMap[player.pk.toString()];

          Icon icon;
          String label;

          if (attended == true) {
            icon = const Icon(Icons.check_circle, color: Colors.green);
            label = "Attending";
          } else if (attended == false) {
            icon = const Icon(Icons.cancel, color: Colors.red);
            label = "Absent";
          } else {
            icon = const Icon(Icons.help_outline, color: Colors.grey);
            label = "No info";
          }

          return ListTile(
            leading: icon,
            title: Text(player.name),
            subtitle: Text(label),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayerDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
