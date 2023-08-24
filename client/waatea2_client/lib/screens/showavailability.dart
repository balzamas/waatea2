import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/showavailability_model.dart';
import '../models/availability_model.dart';
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
    //Get number of players
    final response_user = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}&is_playing=True"),
        headers: {'Authorization': 'Token ${globals.token}'});

    final items_user =
        json.decode(response_user.body).cast<Map<String, dynamic>>();
    List<UserModel> users = items_user.map<UserModel>((json) {
      return UserModel.fromJson(json);
    }).toList();

    int totalUsers = users.length;

    //Get games
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/games_current/filter?club=${globals.clubId}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    String responseBody = utf8.decode(response.bodyBytes);

    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
    List<ShowAvailabilityModel> games =
        items.map<ShowAvailabilityModel>((json) {
      return ShowAvailabilityModel.fromJson(json);
    }).toList();

    //Get availabilities
    for (var i = 0; i < games.length; i++) {
      final responseAvail = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/availabilities/filter?dayofyear=${games[i].dayofyear}&season=${games[i].season}"),
          headers: {'Authorization': 'Token ${globals.token}'});

      if (responseAvail.statusCode == 200) {
        final items =
            json.decode(responseAvail.body).cast<Map<String, dynamic>>();
        List<AvailabilityModel> availabilities =
            items.map<AvailabilityModel>((json) {
          return AvailabilityModel.fromJson(json);
        }).toList();

        int isAvailable = 0;
        int isNotAvailable = 0;
        int isMaybe = 0;
        int isNotSet = 0;

        for (var availability in availabilities) {
          if (availability.state == 3) {
            isAvailable++;
          } else if (availability.state == 1) {
            isNotAvailable++;
          } else if (availability.state == 2) {
            isMaybe++;
          }
        }

        isNotSet = totalUsers - isAvailable - isNotAvailable - isMaybe;

        if (availabilities.isNotEmpty) {
          games[i].isAvailable = isAvailable;
          games[i].isNotAvailable = isNotAvailable;
          games[i].isMaybe = isMaybe;
          games[i].isNotSet = isNotSet;
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
        title: const Text('Game list'),
      ),
      body: Center(
        child: FutureBuilder<List<ShowAvailabilityModel>>(
          future: games,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // By default, show a loading spinner.
            if (!snapshot.hasData) return CircularProgressIndicator();
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
