import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/trainingattendance_model.dart';
import 'package:waatea2_client/models/user_model.dart';
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
  int _totalPlaying = 0;
  bool _loadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayers(); // counts only playing users
    fetchTrainings();
  }

  Future<void> _fetchPlayers() async {
    try {
      final resp = await http.get(
        Uri.parse('${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}'),
        headers: {'Authorization': 'Token ${globals.token}'},
      );
      if (resp.statusCode == 200) {
        final items = json.decode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
        final users = items.map((j) => UserModel.fromJson(j as Map<String, dynamic>)).toList();

        // adjust this accessor if your UserModel has a different profile property
        final playing = users.where((u) => (u.profile?.isPlaying ?? false)).length;

        setState(() {
          _totalPlaying = playing;
          _loadingPlayers = false;
        });
      } else {
        setState(() => _loadingPlayers = false);
      }
    } catch (_) {
      setState(() => _loadingPlayers = false);
    }
  }

  Future<void> fetchTrainings() async {
    final response = await http.get(
      Uri.parse(
        '${globals.URL_PREFIX}/api/trainings/?season=${globals.seasonID}&club=${globals.clubId}',
      ),
      headers: {'Authorization': 'Token ${globals.token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
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
                  review: item['review'],
                ))
            .toList();
      });
    }
  }

  int _missingCountFor(TrainingAttendanceModel t) {
    final m = _totalPlaying - t.attendanceCount - t.nonattendanceCount;
    return m < 0 ? 0 : m;
  }

  void _showAddTrainingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDateTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          20,
          15,
        );

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Add New Training"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
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
                          TimeOfDay.fromDateTime(selectedDateTime).format(context),
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
  child: const Text("Add"),
  onPressed: () async {
    final requestData = {
      "date": selectedDateTime.toUtc().toIso8601String(),
      'club': globals.clubId,
      'season': globals.seasonID,
    };

    try {
      final resp = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/training/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      // Optional: handle errors
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        if (!mounted) return;
        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add training (${resp.statusCode}).')),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error while adding training.')),
      );
      return;
    }

    if (!mounted) return;

    // 1) Close the dialog
    Navigator.of(context).pop();

    // 2) Refresh the list on the same screen
    await fetchTrainings();

    // 3) Optional: show feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Training added.')),
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
        title: const Text('Trainings', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddTrainingDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Training')),
            DataColumn(label: Icon(Icons.check_circle, color: Colors.green)),   // ✅
            DataColumn(label: Icon(Icons.cancel, color: Colors.red)),     // ❌
            DataColumn(label: Icon(Icons.help_outline, color: Colors.orange)), // ❓
          ],
          rows: trainings.map((training) {
            final notSetStr = _loadingPlayers
                ? '…'
                : _missingCountFor(training).toString();

            return DataRow(
              color: training.current
                  ? WidgetStateColor.resolveWith((_) => Colors.lightGreenAccent)
                  : WidgetStateColor.resolveWith((_) => Colors.transparent),
              cells: [
                DataCell(
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TrainingDetailScreen(training: training),
                        ),
                      );
                    },
                    child: Text(
                      "${DateTime.parse(training.date).day}."
                      "${DateTime.parse(training.date).month}."
                      "${DateTime.parse(training.date).year}",
                    ),
                  ),
                ),
                DataCell(Text(training.attendanceCount.toString())), // ✅ count
                DataCell(Text(training.nonattendanceCount.toString())), // ❌ count
                DataCell(
                  Text(
                    notSetStr,
                    style: TextStyle(
                      color: notSetStr == '0' ? Colors.grey : Colors.orange,
                    ),
                  ),
                ), // ❓ count
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
