import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../globals.dart' as globals;
import '../models/training_model.dart';
import '../models/attendance.dart';

class UpcomingTrainingAttendanceScreen extends StatefulWidget {
  const UpcomingTrainingAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<UpcomingTrainingAttendanceScreen> createState() =>
      _UpcomingTrainingAttendanceScreenState();
}

class _UpcomingTrainingAttendanceScreenState
    extends State<UpcomingTrainingAttendanceScreen> {
  late Future<List<TrainingModel>> _future;
  final Map<String, int> _stateByTraining = {}; // 0 unset, 1 yes, 2 no
  final Map<String, String?> _attendancePkByTraining = {}; // pk cache

  @override
  void initState() {
    super.initState();
    _future = _fetchUpcomingTrainings();
  }

  Future<List<TrainingModel>> _fetchUpcomingTrainings() async {
    final resp = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/trainings/?season=${globals.seasonID}&club=${globals.clubId}'),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (resp.statusCode != 200) return [];

    final items = json.decode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
    final all = items
        .map((j) => TrainingModel.fromJson(j as Map<String, dynamic>))
        .toList();

    final now = DateTime.now().toUtc();
    final upcoming = all
        .where((t) => DateTime.parse(t.date).toUtc().isAfter(now))
        .toList()
      ..sort((a, b) =>
          DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    // Vorbelegen: vorhandene Attendance pro Training laden
    for (final t in upcoming) {
      final s = await _loadMyAttendanceStateForTraining(t.id);
      _stateByTraining[t.id] = s;
    }

    return upcoming;
  }

  Future<int> _loadMyAttendanceStateForTraining(String trainingId) async {
    final resp = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/attendances/filter?training=$trainingId&player=${globals.playerId}&season=${globals.seasonID}'),
      headers: {'Authorization': 'Token ${globals.token}'},
    );
    if (resp.statusCode != 200) return 0;

    final list = json.decode(resp.body) as List<dynamic>;
    if (list.isEmpty) return 0;

    final a = AttendanceModel.fromJson(list.first as Map<String, dynamic>);
    _attendancePkByTraining[trainingId] = a.pk;
    return a.attended ? 1 : 2;
  }

  Future<void> _setAttendance({
    required TrainingModel t,
    required int stateValue, // 1 yes, 2 no
  }) async {
    final attended = (stateValue == 1);
    final existingPk = _attendancePkByTraining[t.id];

    if (existingPk != null && existingPk.isNotEmpty) {
      // PATCH
      await http.patch(
        Uri.parse('${globals.URL_PREFIX}/api/attendance/$existingPk/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'attended': attended}),
      );
    } else {
      // POST
      final body = {
        'attended': attended,
        'dayofyear': t.dayofyear,
        'player': globals.playerId,
        'training': t.id,
        'season': globals.seasonID,
      };
      final resp = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/attendance/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = json.decode(resp.body);
        _attendancePkByTraining[t.id] = data['pk']?.toString();
      }
    }

    setState(() {
      _stateByTraining[t.id] = stateValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming trainings')),
      body: FutureBuilder<List<TrainingModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (snap.hasError) {
            return Center(child: Text('Fehler: ${snap.error}'));
          }
          final trainings = snap.data ?? [];
          if (trainings.isEmpty) {
            return const Center(child: Text('Keine zukünftigen Trainings.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _fetchUpcomingTrainings());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trainings.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = trainings[i];
                final when = DateFormat('EEE, d. MMM yyyy – HH:mm')
                    .format(DateTime.parse(t.date).toLocal());
                final state = _stateByTraining[t.id] ?? 0;

                Icon leadingIcon;
                if (state == 1) {
                  leadingIcon =
                      const Icon(Icons.check_circle, color: Colors.green);
                } else if (state == 2) {
                  leadingIcon = const Icon(Icons.cancel, color: Colors.red);
                } else {
                  leadingIcon =
                      const Icon(Icons.help_outline, color: Colors.orange);
                }


                return ListTile(
                  leading: leadingIcon,
                  title: Text("${DateTime.parse(t.date).day}.${DateTime.parse(t.date).month}.${DateTime.parse(t.date).year}" ?? 'Training'),
                  subtitle: Text('$when'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                        onPressed: () => _setAttendance(t: t, stateValue: 1),
                        child: const Text('Yey'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                        onPressed: () => _setAttendance(t: t, stateValue: 2),
                        child: const Text('No'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
