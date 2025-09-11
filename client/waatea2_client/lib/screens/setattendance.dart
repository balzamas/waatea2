import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/upcomingtrainingattendancescreen.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/attendance.dart';
import '../models/setattendance.dart';
import '../models/training_model.dart';

//Todo: programmiert mit Kindergeschrei im Hintergrund, total mess, aufräumen

import 'package:intl/intl.dart';

class SetAttendance extends StatefulWidget {
  const SetAttendance({Key? key}) : super(key: key);
  @override
  SetAttendanceState createState() => SetAttendanceState();
}

class SetAttendanceState extends State<SetAttendance> {
  late Future<SetAttendanceModel> setAttendanceContent;
  late List<UserModel> attendingPlayers;
  List<Map<String, dynamic>> _exercises = [];

  final availabilityListKey = GlobalKey<SetAttendanceState>();
  int state = 0;
  String? attendanceId = "";
  String? trainingId;
  int? dayofhteyear;

  @override
  void initState() {
    super.initState();
    setAttendanceContent = getCurrentTraining();
    // _fetchExercises().then((_) {
    //   _showLastExercisesDialog();
    // });
  }

  Future<void> _fetchExercises() async {
    final response = await http.get(
      Uri.parse(
          "${globals.URL_PREFIX}/api/fitness/filter?season=${globals.seasonID}"),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (response.statusCode == 200) {
      final exercises = json.decode(utf8.decode(response.bodyBytes)) as List;
      setState(() {
        _exercises = exercises.map((e) {
          return {
            'player': e['player_name'],
            'date': DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date'])),
            'note': e['note'],
          };
        }).toList();
      });
    }
  }

  Future<void> _showLastExercisesDialog() async {
    if (_exercises.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Latest fitness entries'),
        content: SingleChildScrollView(
          child: Column(
            children: _exercises.map((exercise) {
              return ListTile(
                leading:
                    RandomAvatar(exercise['player'], height: 50, width: 50),
                title: Text(
                    '${exercise['player']} had gains: ${exercise['note'] ?? 'No note'}'),
                subtitle: Text(exercise['date']),
              );
            }).toList(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Background color
            ),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future setAttendanceNow(int state) async {
    bool boolState = false;
    if (state == 1) {
      boolState = true;
    }
    if (attendanceId != "") {
      final Map<String, bool> body = {
        'attended': boolState,
      };

      final http.Response response = await http.patch(
        Uri.parse('${globals.URL_PREFIX}/api/attendance/$attendanceId/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );
    } else {
      final Map<String, dynamic> body = {
        'attended': boolState,
        'dayofyear': dayofhteyear,
        'player': globals.playerId,
        'training': trainingId,
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

      var data = jsonDecode(response.body);

      attendanceId = data["pk"];
    }
  }

  Future<List<UserModel>> getAttendingPlayers(String trainingid) async {
    final response = await http.get(
        Uri.parse("${globals.URL_PREFIX}/api/attendingusers/$trainingId/"),
        headers: {'Authorization': 'Token ${globals.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<UserModel> attendingPlayers = items.map<UserModel>((json) {
      return UserModel.fromJson(json);
    }).toList();

    return attendingPlayers;
  }

  Future<SetAttendanceModel> getCurrentTraining() async {
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/training_current/filter?club=${globals.clubId}&season=${globals.seasonID}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<TrainingModel> trainings = items.map<TrainingModel>((json) {
      return TrainingModel.fromJson(json);
    }).toList();

    SetAttendanceModel setAttendance = SetAttendanceModel(text: "", state: 0);

    if (trainings.isNotEmpty) {
      trainingId = trainings[0].id;
      attendingPlayers = await getAttendingPlayers(trainingId!);

      dayofhteyear = trainings[0].dayofyear;
      //Load attendance
      final responseAttend = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/attendances/filter?training=${trainings[0].id}&player=${globals.playerId}&season=${globals.seasonID}"),
          headers: {'Authorization': 'Token ${globals.token}'});

      if (responseAttend.statusCode == 200) {
        final items =
            json.decode(responseAttend.body).cast<Map<String, dynamic>>();
        List<AttendanceModel> availabilities =
            items.map<AttendanceModel>((json) {
          return AttendanceModel.fromJson(json);
        }).toList();

        String timePrefix = "Last";

        if (DateTime.parse(trainings[0].date).compareTo(DateTime.now()) > 0) {
          timePrefix = "Next";
        }

        setAttendance.text =
            "$timePrefix training: ${DateTime.parse(trainings[0].date).day}.${DateTime.parse(trainings[0].date).month}.${DateTime.parse(trainings[0].date).year}";

        if (availabilities.length == 1) {
          attendanceId = availabilities[0].pk;
          if (availabilities[0].attended) {
            setAttendance.state = 1;
            state = 1;
          } else {
            setAttendance.state = 2;
            state = 2;
          }
        } else {
          setAttendance.state = 0;
          state = 0;
          setAttendance.text = "${setAttendance.text}\nPlease set attendancy.";
        }
      }
    } else {
      setAttendance.text = "No current training";
      setAttendance.state = -1;
      state = -1;
    }

    return setAttendance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,

      appBar: AppBar(
  title: const Text('Current training',
    style: TextStyle(color: Colors.white)),
  actions: [
    IconButton(
      tooltip: 'Upcoming trainings',
      icon: const Icon(Icons.event_available_outlined),
      onPressed: () async {
        // Screen öffnen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const UpcomingTrainingAttendanceScreen(),
          ),
        );

        // (Optional) Nach Rückkehr den „Aktuell“-Screen neu laden,
        // falls sich deine Teilnahme geändert hat:
        setState(() {
          setAttendanceContent = getCurrentTraining();
        });
      },
    ),
  ],
),
      body: Center(
        child: FutureBuilder<SetAttendanceModel>(
          future: setAttendanceContent,
          builder: (BuildContext context,
              AsyncSnapshot<SetAttendanceModel> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                color: Colors.black,
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final setAttendance = snapshot.data;

              if (setAttendance == null) {
                return const Text('Loading...');
              }

              Icon icon;

              if (state == 1) {
                icon = const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 150);
              } else if (state == 2) {
                icon = const Icon(Icons.highlight_off_outlined,
                    color: Colors.red, size: 150);
              } else if (state == 0) {
                icon = const Icon(Icons.help_outline,
                    color: Colors.orange, size: 150);
              } else {
                icon = const Icon(Icons.self_improvement_outlined,
                    color: Colors.black, size: 150);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    setAttendance.text,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  icon,
                  if (state > -1) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Attending/Attended?",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black),
                          onPressed: () {
                            setAttendance.state = 1;
                            state = 1;
                            setState(() {
                              state = 1;
                            });
                            setAttendanceNow(1);
                          },
                          child: const Text("Yey!",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black),
                          onPressed: () {
                            setAttendance.state = 2;
                            state = 2;
                            setState(() {
                              state = 2;
                            });
                            setAttendanceNow(2);
                          },
                          child: const Text("No",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      "Your attendance rate:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${globals.player.attendancePercentage}%",
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                    if (globals.player.attendancePercentage > 79) ...[
                      const Text(
                        "❤️LOVELY!❤️",
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.bold),
                      )
                    ],
                                        const SizedBox(height: 50),
                    Center(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10, // Number of avatars per row
                          mainAxisSpacing: 2.0, // Vertical spacing between rows
                          crossAxisSpacing:
                              2.0, // Horizontal spacing between avatars
                        ),
                        shrinkWrap:
                            true, // Wrap content inside a SingleChildScrollView if needed
                        itemCount: attendingPlayers.length,
                        itemBuilder: (BuildContext context, int index) {
                          return RandomAvatar(attendingPlayers[index].name,
                              height: 800, width: 1000);
                          //ToDo Umlauts
                        },
                      ),
                    ),
                  ]
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
