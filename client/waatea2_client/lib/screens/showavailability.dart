import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/showavailability_model.dart';
import '../models/user_model.dart';

import '../widgets/showavailability_row.dart';

class ShowAvailability extends StatefulWidget {
  ShowAvailability();
  @override
  ShowAvailabilityState createState() => ShowAvailabilityState();
}

class ShowAvailabilityState extends State<ShowAvailability> {
  late Future<List<ShowAvailabilityModel>> games;
  final availabilityListKey = GlobalKey<ShowAvailabilityState>();

  @override
  void initState() {
    super.initState();
    games = getGameList();
  }

  Future<List<ShowAvailabilityModel>> getGameList() async {
    //Get games
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/games_current_avail/filter?club=${globals.clubId}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    String responseBody = utf8.decode(response.bodyBytes);

    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
    List<ShowAvailabilityModel> games =
        items.map<ShowAvailabilityModel>((json) {
      return ShowAvailabilityModel.fromJson(json);
    }).toList();

    return games;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: const Text('Game list'),
      ),
      body: Center(
        child: FutureBuilder<List<ShowAvailabilityModel>>(
          future: games,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // By default, show a loading spinner.
            if (!snapshot.hasData)
              return CircularProgressIndicator(color: Colors.black);
            // Render employee lists
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                var data = snapshot.data[index];

                return ShowAvailabilityRow(
                    gameId: data.pk,
                    game: data.home + " - " + data.away,
                    gameDate: data.date,
                    dayofyear: data.dayofyear,
                    isAvailable: data.isAvailable,
                    isNotAvailable: data.isNotAvailable,
                    isMaybe: data.isMaybe,
                    isNotSet: data.isNotSet,
                    season: data.season);
              },
            );
          },
        ),
      ),
    );
  }
}
