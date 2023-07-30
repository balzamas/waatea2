import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;
import 'package:intl/intl.dart';

class SetAvailabilityRow extends StatefulWidget {
  final String gameId;
  final String game;
  final String date;
  final int initialState;
  final int playerId;
  final String token;
  final String initialAvailabilityId;
  final String clubId;
  final int dayofyear;
  final String season;

  const SetAvailabilityRow(
      {Key? key,
      required this.gameId,
      required this.game,
      required this.date,
      required this.initialState,
      required this.playerId,
      required this.token,
      required this.initialAvailabilityId,
      required this.clubId,
      required this.dayofyear,
      required this.season})
      : super(key: key);

  @override
  _SetAvailabilityRowState createState() => _SetAvailabilityRowState();
}

class _SetAvailabilityRowState extends State<SetAvailabilityRow> {
  int state = 0;
  String availabilityId = "";

  @override
  void initState() {
    super.initState();
    state = widget.initialState;
    availabilityId = widget.initialAvailabilityId;
  }

  Future<void> _submitMutation(
    BuildContext context,
    String gameId,
    int playerId,
    int state,
    String token,
  ) async {
    if (availabilityId != "") {
      final Map<String, int> body = {
        'state': state,
      };

      final http.Response response = await http.patch(
        Uri.parse('${globals.URL_PREFIX}/api/availability/$availabilityId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );
    } else {
      final Map<String, dynamic> body = {
        'state': state.toString(),
        'player': widget.playerId.toString(),
        'club': widget.clubId,
        'dayofyear': widget.dayofyear,
        'season': widget.season
      };

      final http.Response response = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/availability/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );

      var data = jsonDecode(response.body);

      availabilityId = data["pk"];
    }

    // Update the state with the new value after the HTTP request is completed
    setState(() {
      this.state = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    Icon icon;

    if (state == 1) {
      icon = const Icon(
        Icons.thumb_up_alt_outlined,
        color: Colors.green,
      );
    } else if (state == 2) {
      icon = const Icon(
        Icons.thumb_down_alt_outlined,
        color: Colors.red,
      );
    } else if (state == 3) {
      icon = const Icon(
        Icons.question_mark,
        color: Colors.orange,
      );
    } else {
      icon = const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          int newState = state;
          if (state > 2) {
            newState = 1;
          } else {
            newState = state + 1;
          }
          _submitMutation(
            context,
            widget.gameId,
            widget.playerId,
            newState,
            widget.token,
          );
        },
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.game,
                    style: Theme.of(context).textTheme.headline6?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    widget.date,
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
