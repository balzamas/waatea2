import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:waatea2_client/models/game_model.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/setavailability_model.dart';
import '../models/availability_model.dart';
import '../widgets/setavailability_row.dart';

class SetAvailability extends StatefulWidget {
  late final int playerId;
  SetAvailability(this.playerId);
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
    final formatter_date = DateFormat('dd.MM.yyyy EEEE');
    final formatter_time = DateFormat('HH:mm');

    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/games_current/filter?club=${globals.clubId}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<GameModel> games = items.map<GameModel>((json) {
      return GameModel.fromJson(json);
    }).toList();

    List<SetAvailabilityModel> setAvailabilities = [];

    for (var i = 0; i < games.length; i++) {
      if (i > 0 && games[i].dayofyear == games[i - 1].dayofyear) {
        DateTime gameDate = DateTime.parse(games[i].date);

        setAvailabilities[setAvailabilities.length - 1].games =
            "${setAvailabilities[setAvailabilities.length - 1].games}\n${formatter_time.format(gameDate)} - ${games[i].home} - ${games[i].away}";
      } else {
        DateTime gameDate = DateTime.parse(games[i].date);
        SetAvailabilityModel record = SetAvailabilityModel(
            avail_id: "",
            games:
                "${formatter_time.format(gameDate)} - ${games[i].home} - ${games[i].away}",
            dayofyear: games[i].dayofyear,
            date: formatter_date.format(gameDate),
            state: 0,
            season: games[i].season);
        final responseAvail = await http.get(
            Uri.parse(
                "${globals.URL_PREFIX}/api/availabilities/filter?dayofyear=${games[i].dayofyear}&player=${widget.playerId}&season=${games[i].season}"),
            headers: {'Authorization': 'Token ${globals.token}'});

        if (responseAvail.statusCode == 200) {
          final items =
              json.decode(responseAvail.body).cast<Map<String, dynamic>>();
          List<AvailabilityModel> availabilities =
              items.map<AvailabilityModel>((json) {
            return AvailabilityModel.fromJson(json);
          }).toList();

          if (availabilities.isNotEmpty) {
            record.state = availabilities[0].state;
            record.avail_id = availabilities[0].pk;
          }

          setAvailabilities.add(record);
        }
      }
    }

    return setAvailabilities;
  }

  @override
  Widget build(BuildContext context) {
    final isTopLevelScreen = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      key: availabilityListKey,
      appBar: isTopLevelScreen
          ? null
          : AppBar(
              title: Text('Set availability'),
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
                    game: data.games,
                    date: data.date,
                    initialState: data.state,
                    playerId: widget.playerId,
                    initialAvailabilityId: data.avail_id,
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
