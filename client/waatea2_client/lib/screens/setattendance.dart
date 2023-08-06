import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:waatea2_client/models/game_model.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/attendance.dart';
import '../models/setattendance.dart';
import '../models/setavailability_model.dart';
import '../models/availability_model.dart';
import '../models/training_model.dart';
import '../widgets/setavailability_row.dart';

//Todo: programmiert mit Kindergeschrei im Hintergrund, total mess, aufräumen

class SetAttendance extends StatefulWidget {
  late final String token;
  late final String clubId;
  late final int userId;
  late final String season;
  SetAttendance(this.token, this.clubId, this.userId, this.season);
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
          'Authorization': 'Token ${widget.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );
    } else {
      final Map<String, dynamic> body = {
        'attended': boolState,
        'club': widget.clubId,
        'dayofyear': this.dayofhteyear,
        'season': widget.season,
        'player': widget.userId,
        'training': this.trainingId
      };

      final http.Response response = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/attendance/'),
        headers: {
          'Authorization': 'Token ${widget.token}',
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
            "${globals.URL_PREFIX}/api/training_current/filter?club=${widget.clubId}&season=${widget.season}"),
        headers: {'Authorization': 'Token ${widget.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<TrainingModel> trainings = items.map<TrainingModel>((json) {
      return TrainingModel.fromJson(json);
    }).toList();

    SetAttendanceModel setAttendance = SetAttendanceModel(text: "", state: 0);

    if (trainings.length > 0) {
      this.trainingId = trainings[0].pk;
      this.dayofhteyear = trainings[0].dayofyear;
      //Load attendance
      final responseAttend = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/attendances/filter?dayofyear=${trainings[0].dayofyear}&player=${widget.userId}&season=${widget.season}"),
          headers: {'Authorization': 'Token ${widget.token}'});

      if (responseAttend.statusCode == 200) {
        final items =
            json.decode(responseAttend.body).cast<Map<String, dynamic>>();
        List<AttendanceModel> availabilities =
            items.map<AttendanceModel>((json) {
          return AttendanceModel.fromJson(json);
        }).toList();

        String time_prefix = "Last";

        if (DateTime.parse(trainings[0].date).compareTo(DateTime.now()) > 0) {
          time_prefix = "Next";
        }

        setAttendance.text =
            "$time_prefix training: ${DateTime.parse(trainings[0].date).day}.${DateTime.parse(trainings[0].date).month}.${DateTime.parse(trainings[0].date).year}";

        if (availabilities.length == 1) {
          attendanceId = availabilities[0].pk;
          if (availabilities[0].attended) {
            setAttendance.state = 1;
            this.state = 1;
          } else {
            setAttendance.state = 2;
            this.state = 2;
          }
        } else {
          setAttendance.state = 0;
          this.state = 0;
          setAttendance.text = setAttendance.text + "\nPlease set attendancy.";
        }
      }
    } else {
      setAttendance.text = "No current training";
      setAttendance.state = -1;
      this.state = -1;
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

              if (this.state == 1) {
                icon = const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 150);
              } else if (this.state == 2) {
                icon = const Icon(Icons.highlight_off_outlined,
                    color: Colors.red, size: 150);
              } else if (this.state == 0) {
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
                            this.state = 1;
                            setState(() {
                              this.state = 1;
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
                            this.state = 2;
                            setState(() {
                              this.state = 2;
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
