import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/attendance.dart';
import '../models/setattendance.dart';
import '../models/training_model.dart';

//Todo: programmiert mit Kindergeschrei im Hintergrund, total mess, aufräumen

class SetAttendance extends StatefulWidget {
  const SetAttendance();
  @override
  SetAttendanceState createState() => SetAttendanceState();
}

class SetAttendanceState extends State<SetAttendance> {
  late Future<SetAttendanceModel> setAttendanceContent;
  final availabilityListKey = GlobalKey<SetAttendanceState>();
  int state = 0;
  String? attendanceId = "";
  String? trainingId;
  int? dayofhteyear;

  @override
  void initState() {
    super.initState();
    setAttendanceContent = getCurrentTraining();
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
        title: const Text('Current training'),
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
                                  fontSize: 18, fontWeight: FontWeight.bold)),
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
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Text(
                      "Your attendance rate:",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${globals.player.attendancePercentage}%",
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                    if (globals.player.attendancePercentage > 79) ...[
                      Text(
                        "❤️LOVELY!❤️",
                        style: const TextStyle(
                            fontSize: 23, fontWeight: FontWeight.bold),
                      )
                    ]
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
