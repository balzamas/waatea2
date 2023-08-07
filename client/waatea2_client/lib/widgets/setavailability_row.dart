import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/helper.dart';
import '../globals.dart' as globals;

class SetAvailabilityRow extends StatefulWidget {
  final String game;
  final String date;
  final int initialState;
  final int playerId;
  final String initialAvailabilityId;
  final int dayofyear;
  final String season;

  const SetAvailabilityRow(
      {Key? key,
      required this.game,
      required this.date,
      required this.initialState,
      required this.playerId,
      required this.initialAvailabilityId,
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
    int playerId,
    int state,
  ) async {
    if (availabilityId != "") {
      final Map<String, int> body = {
        'state': state,
      };

      final http.Response response = await http.patch(
        Uri.parse('${globals.URL_PREFIX}/api/availability/$availabilityId/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );
    } else {
      final Map<String, dynamic> body = {
        'state': state.toString(),
        'player': widget.playerId.toString(),
        'club': globals.clubId,
        'dayofyear': widget.dayofyear,
        'season': widget.season
      };

      final http.Response response = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/availability/'),
        headers: {
          'Authorization': 'Token ${globals.token}',
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

    icon = returnStateIcon(state);

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
            widget.playerId,
            newState,
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
                    widget.date,
                    style: Theme.of(context).textTheme.headline6?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    widget.game,
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
