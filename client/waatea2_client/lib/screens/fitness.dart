import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import '../globals.dart' as globals;

class Fitness extends StatefulWidget {
  final int playerId = globals.playerId;

  Fitness({Key? key}) : super(key: key);

  @override
  _FitnessState createState() => _FitnessState();
}

class _FitnessState extends State<Fitness> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    final response = await http.get(
      Uri.parse(
          "${globals.URL_PREFIX}/api/fitness/filter?player=${widget.playerId}&season=${globals.seasonID}"),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (response.statusCode == 200) {
      final exercises = json.decode(utf8.decode(response.bodyBytes)) as List;
      setState(() {
        _exercises = exercises.map((e) {
          return {
            'date': DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date'])),
            'note': e['note'],
          };
        }).toList();
      });
    }
  }

  Future<void> _submitExercise(int points, String note) async {
    setState(() {
      _isSubmitting = true;
    });

    final date = DateTime.now().toUtc().toIso8601String();
    final season = globals.seasonID;

    // Check if there's already an exercise entry for today
    final responseCheck = await http.get(
      Uri.parse(
          "${globals.URL_PREFIX}/api/fitness/filter?player=${widget.playerId}&date=$date&season=$season"),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (responseCheck.statusCode == 200) {
      final existingEntries = json.decode(responseCheck.body) as List;
      if (existingEntries.isNotEmpty) {
        final confirm = await _showConfirmationDialog();
        if (!confirm) {
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }
    }

    // Submit the exercise entry
    final response = await http.post(
      Uri.parse("${globals.URL_PREFIX}/api/fitness/"),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pk': '', // Assign a proper pk if required by your backend
        'player': widget.playerId,
        'date': date,
        'season': season,
        'points': points,
        'note': note,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise recorded successfully!')),
      );
      _fetchExercises(); // Refresh the exercise list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record exercise.')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmation'),
            content: Text(
                'You already have an exercise recorded for today. Are you cheating or are you a beast?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Background color
                ),
                child: Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showNoteDialog(int points) async {
    _noteController.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('What did you do?'),
        content: TextField(
          controller: _noteController,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: 'Add a note',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_noteController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Background color
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null) {
      _submitExercise(points, result);
    }
  }

  void _showExerciseInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fitness Point System'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moderate',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Moderate strength/cardio'),
              Text('For example:'),
              Text('Short Runs (4–5 km)'),
              Text('Moderate Swimming (20–30 minutes, steady pace)'),
              Text('Cycling (10–15 km)'),
              Text('Gym session  (min. 30 - 40 min)'),
              Text('Normal Rugby training'),

              SizedBox(height: 16),
              Text(
                'Challenging',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Challenging strength/cardio'),
              Text('For example:'),
              Text('Longer Runs (>6 km)'),
              Text('Intense Swimming (30–45 minutes, intervals or fast pace)'),
              Text('Cycling (>15 km with some hills or higher intensity)'),
              Text('Touch Rugby (lasting at least 45 minutes)'),
              Text('Structured stength/hypertrophy gym program'),

              SizedBox(height: 16),
              Text(
                'Game Conditioning',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('One of these drills:'),
              SizedBox(height: 8),
              SizedBox(height: 16),
              Text('Drill 1: Shuttle Run'),
              SizedBox(height: 8),
              Image.asset('assets/shuttle_run.png'), // Example image
              Text(
                  'Setup: Cones 30m apart\nWork: Complete 4 Sets\nGuidance: Forwards: 5-7 shuttles per minute, Backs: 7-9 shuttles per minute'),
              SizedBox(height: 16),
              Text('Drill 2: Figure of 8 run'),
              SizedBox(height: 8),
              Image.asset('assets/figure_of_8.png'), // Example image
              Text(
                  'Setup: No setup required\nWork: Complete 4-5 Sets\nGuidance: Run at consistent speed'),
              SizedBox(height: 16),
              Text('Drill 3: Scotland Drill'),
              SizedBox(height: 8),
              Image.asset('assets/scotland_drill.png'), // Example image
              Text(
                  'Setup: Cones 5m & 22m\nWork: Complete 3-6 Sets\nGuidance: Goal is to do the running in 20s with 10s rest on a 30 second rolling clock. Increase time if too hard. Further possibility to split in 2 groups with different times'),
              SizedBox(height: 16),
              Text('Drill 4: Complex Shuttles'),
              SizedBox(height: 8),
              Image.asset('assets/complex_shuttles.png'), // Example image
              Text(
                  'Setup: Cones 5m & 22m\nWork: 2-4 Sets\nGuidance: Goal is to do the running 60 second rolling clock. Increase time if too hard. Further possibility to split in 2 groups with different times'),
              SizedBox(height: 16),
              Text('Drill 5: Broken Broncos'),
              SizedBox(height: 8),
              Image.asset('assets/broken_broncos.png'), // Example image
              Text(
                  'Setup: Cones at 20m / 40m / 60m\nWork: 5 Reps\nGuidance: Goal is to do the running 90 second rolling clock (complete Bronco and rest until 90 sec)\nStandards: <50 secs Excellent, <60secs Good, <70 secs Average'),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitness'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showExerciseInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _showNoteDialog(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Background color
                padding: EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20), // Button size
                textStyle: TextStyle(fontSize: 18), // Text size
              ),
              child: Text('Moderate'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _showNoteDialog(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Background color
                padding: EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20), // Button size
                textStyle: TextStyle(fontSize: 18), // Text size
              ),
              child: Text('Challenging'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _showNoteDialog(4),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Background color
                padding: EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20), // Button size
                textStyle: TextStyle(fontSize: 18), // Text size
              ),
              child: Text('Game Conditioning'),
            ),
            if (_isSubmitting) ...[
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
            SizedBox(height: 32), // Space before the list of exercises
            Expanded(
              child: ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return ListTile(
                    title: Text(exercise['date']),
                    subtitle: Text(exercise['note'] ?? 'No note'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
