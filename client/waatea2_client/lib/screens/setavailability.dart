import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/game_model.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/setavailability_model.dart';
import '../models/availability_model.dart';
import '../widgets/setavailability_row.dart';

class SetAvailability extends StatefulWidget {
  late final String token;
  late final String clubid;
  late final int userid;
  SetAvailability(this.token, this.clubid, this.userid);
  @override
  SetAvailabilityState createState() => SetAvailabilityState();
}

class SetAvailabilityState extends State<SetAvailability> {
  late Future<List<SetAvailabilityModel>> games;
  final availabilityListKey = GlobalKey<SetAvailabilityState>();

  @override
  void initState() {
    super.initState();
    games = getGameList();
  }

  Future<List<SetAvailabilityModel>> getGameList() async {
    final response = await http.get(
        Uri.parse("${globals.URL_PREFIX}/api/games_current/filter?club=" +
            widget.clubid),
        headers: {'Authorization': 'Token ${widget.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<SetAvailabilityModel> games = items.map<SetAvailabilityModel>((json) {
      return SetAvailabilityModel.fromJson(json);
    }).toList();

    for (var i = 0; i < games.length; i++) {
      final responseAvail = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/availabilities/filter?dayofyear=${games[i].dayofyear}&player=${widget.userid}&season=${games[i].season}"),
          headers: {'Authorization': 'Token ${widget.token}'});

      if (responseAvail.statusCode == 200) {
        final items =
            json.decode(responseAvail.body).cast<Map<String, dynamic>>();
        List<AvailabilityModel> availabilities =
            items.map<AvailabilityModel>((json) {
          return AvailabilityModel.fromJson(json);
        }).toList();
        if (availabilities.isNotEmpty) {
          games[i].state = availabilities[0].state;
          games[i].avail_id = availabilities[0].pk;
        }
      }
    }

    return games;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: const Text('Set your availability'),
      ),
      body: Center(
        child: FutureBuilder<List<SetAvailabilityModel>>(
          future: games,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // By default, show a loading spinner.
            if (!snapshot.hasData) return CircularProgressIndicator();
            // Render employee lists
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                var data = snapshot.data[index];

                return SetAvailabilityRow(
                    gameId: data.pk,
                    game: data.home + " - " + data.away,
                    date: data.date,
                    initialState: data.state,
                    playerId: widget.userid,
                    token: widget.token,
                    initialAvailabilityId: data.avail_id,
                    clubId: widget.clubid,
                    dayofyear: data.dayofyear,
                    season: data.season);
              },
            );
          },
        ),
      ),
    );
  }
}
