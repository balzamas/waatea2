import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/trainingattendance_model.dart';
import '../globals.dart' as globals;

class ShowAttendance extends StatefulWidget {
  late final String token;
  late final String season;

  ShowAttendance(this.token, this.season);

  @override
  _ShowAttendanceState createState() => _ShowAttendanceState();
}

class _ShowAttendanceState extends State<ShowAttendance> {
  List<TrainingAttendanceModel> trainings = [];

  @override
  void initState() {
    super.initState();
    fetchTrainings();
  }

  Future<void> fetchTrainings() async {
    final response = await http.get(
        Uri.parse(
            '${globals.URL_PREFIX}/api/trainings/?season=${widget.season}'),
        headers: {'Authorization': 'Token ${widget.token}'});
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        trainings = data
            .map((item) => TrainingAttendanceModel(
                  pk: item['id'],
                  date: item['date'],
                  club: item['club'],
                  season: item['season'],
                  dayofyear: item['dayofyear'],
                  attendanceCount: item['attendance_count'],
                ))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trainings'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Training')),
            DataColumn(label: Text('Attending')),
          ],
          rows: trainings.map((training) {
            return DataRow(cells: [
              DataCell(Text(
                  "${DateTime.parse(training.date).day}.${DateTime.parse(training.date).month}.${DateTime.parse(training.date).year}")),
              DataCell(Text(training.attendanceCount.toString())),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
