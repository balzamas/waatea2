import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;

class ShowPlayerAttendance extends StatefulWidget {
  final int player;
  final int last_n;
  final MainAxisAlignment alignment;

  const ShowPlayerAttendance(this.player, this.last_n, this.alignment, {Key? key}) : super(key: key);

  @override
  _ShowPlayerAttendanceState createState() => _ShowPlayerAttendanceState();
}

class AttendedViewModel {
  final String date;
  final bool attended;

  AttendedViewModel({required this.date, required this.attended});
}

class _ShowPlayerAttendanceState extends State<ShowPlayerAttendance> {
  late Future<List<AttendedViewModel>> trainAttendList;

  @override
  void initState() {
    super.initState();
    trainAttendList = fetchTrainings();
  }

  Future<List<AttendedViewModel>> fetchTrainings() async {
    List<AttendedViewModel> trainingsX = [];
    final response = await http.get(
        Uri.parse(
            '${globals.URL_PREFIX}/api/training-attendance?season=${globals.seasonID}&club=${globals.clubId}&user_id=${widget.player}&last_n=${widget.last_n}'),
        headers: {'Authorization': 'Token ${globals.token}'});
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      trainingsX = data
          .map((item) => AttendedViewModel(
                date: item['date'],
                attended: item['attended'],
              ))
          .toList();
    }
    return trainingsX;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FutureBuilder<List<AttendedViewModel>>(
          future: trainAttendList,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // By default, show a loading spinner.
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Colors.black);
            }
            // Render icons with dates under each icon
            return Container(
              color: Colors.transparent, // Set transparent background
              child: Row(
                mainAxisAlignment: widget.alignment,
                children: snapshot.data.map<Widget>((data) {
                  return Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.square,
                          size: 20.0,
                          color: data.attended ? Colors.green : Colors.grey,
                        ),
                        // SizedBox(height: 4), // Adding spacing
                        // Text(data.date),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
