import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/trainingattendance_model.dart';
import 'package:waatea2_client/screens/home.dart';
import 'package:waatea2_client/screens/trainingdetail.dart';
import '../globals.dart' as globals;

class ShowAttendance extends StatefulWidget {
  const ShowAttendance({Key? key}) : super(key: key);

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
            '${globals.URL_PREFIX}/api/trainings/?season=${globals.seasonID}&club=${globals.clubId}'),
        headers: {'Authorization': 'Token ${globals.token}'});
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
                nonattendanceCount: item['nonattendance_count'],
                current: item['current'],
                remarks: item['remarks'],
                review: item['review']))
            .toList();
      });
    }
  }

  void _showAddTrainingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDateTime = DateTime(DateTime.now().year,
            DateTime.now().month, DateTime.now().day, 20, 30);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Add New Training"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDateTime = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDateTime != null &&
                          pickedDateTime != selectedDateTime) {
                        setState(() {
                          selectedDateTime = DateTime(pickedDateTime.year,
                              pickedDateTime.month, pickedDateTime.day, 20, 30);
                        });
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 10),
                        Text(
                          "${selectedDateTime.toLocal()}".split(' ')[0],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.access_time),
                        const SizedBox(width: 10),
                        Text(
                          TimeOfDay.fromDateTime(selectedDateTime)
                              .format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Add"),
                  onPressed: () async {
                    final requestData = {
                      "date": selectedDateTime.toUtc().toIso8601String(),
                      'club': globals.clubId,
                      'season': globals.seasonID
                    };

                    try {
                      final response = await http.post(
                        Uri.parse('${globals.URL_PREFIX}/api/training/'),
                        headers: {
                          'Authorization': 'Token ${globals.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(requestData),
                      );

                      if (response.statusCode == 201) {
                        // Training added successfully, handle the response if needed
                      } else {
                        // Handle error if necessary
                      }
                    } catch (error) {
                      // Handle error if necessary
                    }

                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyHomePage(initialIndex: 5),
                      ),
                    );
                  },
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
      appBar: AppBar(
        title: const Text('Trainings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              _showAddTrainingDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Training')),
            DataColumn(label: Text('Attendance')),
            DataColumn(label: Text('Nope')),
          ],
          rows: trainings.map((training) {
            if (training.current) {
              print(training.date);
            }
            return DataRow(
                color: training.current
                    ? WidgetStateColor.resolveWith(
                        (states) => Colors.lightGreenAccent)
                    : WidgetStateColor.resolveWith(
                        (states) => Colors.transparent),
                cells: [
                  DataCell(
                    GestureDetector(
                      onTap: () {
                        // Navigate to the TrainingDetailScreen with the selected training
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TrainingDetailScreen(training: training),
                          ),
                        );
                      },
                      child: Text(
                        "${DateTime.parse(training.date).day}.${DateTime.parse(training.date).month}.${DateTime.parse(training.date).year}",
                      ),
                    ),
                  ),
                  DataCell(Text(training.attendanceCount.toString())),
                  DataCell(Text(training.nonattendanceCount.toString())),
                ]);
          }).toList(),
        ),
      ),
    );
  }
}
