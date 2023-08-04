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

class SetAttendance extends StatefulWidget {
  late final String token;
  late final String clubid;
  late final int userid;
  late final String season;
  SetAttendance(this.token, this.clubid, this.userid, this.season);
  @override
  SetAttendanceState createState() => SetAttendanceState();
}

class SetAttendanceState extends State<SetAttendance> {
  late Future<SetAttendanceModel> setAttendanceContent;
  final availabilityListKey = GlobalKey<SetAttendanceState>();

  @override
  void initState() {
    super.initState();
    setAttendanceContent = getCurrentTraining();
  }

  Future<SetAttendanceModel> getCurrentTraining() async {
    final formatter_date = DateFormat('dd.MM.yyyy EEEE');
    final formatter_time = DateFormat('HH:mm');

    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/training_current/filter?club=${widget.clubid}&season=${widget.season}"),
        headers: {'Authorization': 'Token ${widget.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<TrainingModel> trainings = items.map<TrainingModel>((json) {
      return TrainingModel.fromJson(json);
    }).toList();

    SetAttendanceModel setAttendance = SetAttendanceModel(text: "", state: 0);

    if (trainings.length > 0) {
      //Load attendance
      final responseAttend = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/attendances/filter?dayofyear=${trainings[0].dayofyear}&player=${widget.userid}&season=${widget.season}"),
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
          if (availabilities[0].attended) {
            setAttendance.state = 1;
          } else {
            setAttendance.state = 2;
          }
        } else {
          setAttendance.state = 0;
          setAttendance.text = setAttendance.text + "\nPlease set attendancy.";
        }
      }
    } else {
      setAttendance.text = "No current training";
      setAttendance.state = -1;
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
            // By default, show a loading spinner.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // Access the data from the future and show the text and state.
              final setAttendance = snapshot.data;

              if (setAttendance == null) {
                // No data available yet or some other issue.
                return Text('Loading...');
              }

              Icon icon;

              if (setAttendance.state == 1) {
                icon = const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 150);
              } else if (setAttendance.state == 2) {
                icon = const Icon(Icons.highlight_off_outlined,
                    color: Colors.red, size: 150);
              } else if (setAttendance.state == 0) {
                icon = const Icon(Icons.help_outline,
                    color: Colors.orange, size: 150);
              } else {
                icon = const Icon(Icons.self_improvement_outlined,
                    color: Colors.black, size: 150);
              }

              // You can display the text and state however you want.
              // Here, we're using a Column widget to show the text and state under each other.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(setAttendance.text,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  icon,
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
