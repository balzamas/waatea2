import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/attendance.dart';
import '../models/setattendance.dart';
import '../models/training_model.dart';

//Todo: programmiert mit Kindergeschrei im Hintergrund, total mess, aufräumen

class SetAttendance extends StatefulWidget {
  late final int userId;
  SetAttendance(this.userId);
  @override
  SetAttendanceState createState() => SetAttendanceState();
}

class SetAttendanceState extends State<SetAttendance> {
  late Future<SetAttendanceModel> setAttendanceContent;
  final availabilityListKey = GlobalKey<SetAttendanceState>();
  int state = 0;
  String? attendanceId = "";
  String? trainingId = null;
  int? dayofhteyear = null;

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
    if (this.attendanceId != "") {
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
        'player': widget.userId,
        'training': trainingId
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
    name(params) {}
  }

  Future<SetAttendanceModel> getCurrentTraining() async {
    final formatter_date = DateFormat('dd.MM.yyyy EEEE');
    final formatter_time = DateFormat('HH:mm');

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
      trainingId = trainings[0].pk;
      dayofhteyear = trainings[0].dayofyear;
      //Load attendance
      final responseAttend = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/attendances/filter?training=${trainings[0].pk}&player=${widget.userId}&season=${globals.seasonID}"),
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
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final setAttendance = snapshot.data;

              if (setAttendance == null) {
                return Text('Loading...');
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  icon,
                  if (this.state > -1) ...[
                    SizedBox(height: 20),
                    Text(
                      "Attending/Attended?",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setAttendance.state = 1;
                            state = 1;
                            setState(() {
                              state = 1;
                            });
                            setAttendanceNow(1);
                          },
                          child: Text("Yes",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            setAttendance.state = 2;
                            state = 2;
                            setState(() {
                              state = 2;
                            });
                            setAttendanceNow(2);
                          },
                          child: Text("No",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
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
