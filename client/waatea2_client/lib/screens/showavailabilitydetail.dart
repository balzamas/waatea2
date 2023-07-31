import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/showavailability_model.dart';
import '../models/availability_model.dart';
import '../models/showavailabilitydetail_model.dart';
import '../models/user_model.dart';

import '../widgets/showavailability_row.dart';
import '../widgets/showavailabilitydetail_row.dart';

class ShowAvailabilityDetail extends StatefulWidget {
  late final String token;
  late final String clubid;
  late final String gameid;
  late final String game;
  late final String gameDate;
  late final int dayofyear;
  late final String season;
  late final isAvailable;
  late final int isNotAvailable;
  late final int isMaybe;
  late final int isNotSet;

  ShowAvailabilityDetail(
      this.token,
      this.clubid,
      this.gameid,
      this.game,
      this.gameDate,
      this.dayofyear,
      this.season,
      this.isAvailable,
      this.isNotAvailable,
      this.isMaybe,
      this.isNotSet);
  @override
  ShowAvailabilityDetailState createState() => ShowAvailabilityDetailState();
}

class ShowAvailabilityDetailState extends State<ShowAvailabilityDetail> {
  late Future<List<ShowAvailabilityDetailModel>> games;
  final availabilityListKey = GlobalKey<ShowAvailabilityDetailState>();

  @override
  void initState() {
    super.initState();
    games = getPlayerList();
  }

  Future<List<ShowAvailabilityDetailModel>> getPlayerList() async {
    //Get players
    final response_player = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/users/filter?club=" + widget.clubid),
        headers: {'Authorization': 'Token ${widget.token}'});

    final items_players =
        json.decode(response_player.body).cast<Map<String, dynamic>>();
    List<ShowAvailabilityDetailModel> players =
        items_players.map<ShowAvailabilityDetailModel>((json) {
      return ShowAvailabilityDetailModel.fromJson(json);
    }).toList();

    final responseAvail = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/availabilities/filter?dayofyear=${widget.dayofyear}&season=${widget.season}"),
        headers: {'Authorization': 'Token ${widget.token}'});

    if (responseAvail.statusCode == 200) {
      final items_availability =
          json.decode(responseAvail.body).cast<Map<String, dynamic>>();
      List<AvailabilityModel> availabilities =
          items_availability.map<AvailabilityModel>((json) {
        return AvailabilityModel.fromJson(json);
      }).toList();

      //Get availabilities
      for (var i = 0; i < players.length; i++) {
        var myListFiltered =
            availabilities.where((e) => e.player == players[i].pk);
        if (myListFiltered.length == 1) {
          players[i].state = myListFiltered.first.state;
          if (myListFiltered.first.updated != "") {
            DateTime updated = DateTime.parse(myListFiltered.first.updated);
            players[i].updated =
                '${updated.day}.${updated.month}.${updated.year} ${updated.hour}:${updated.minute}';
          }
        } else if (myListFiltered.length > 1) {
          print("Error! Too many availabilities");
        }
      }
    }

    return players;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: Text(widget.game + " // " + widget.gameDate),
      ),
      body: Column(
        // Wrap the body with a Column
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Add your static information here
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${widget.isAvailable}, ${widget.isNotAvailable}, ${widget.isMaybe}, ${widget.isNotSet}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ShowAvailabilityDetailModel>>(
              future: games,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                // By default, show a loading spinner.
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    var data = snapshot.data[index];

                    return ShowAvailabilityDetailRow(
                        name: data.name,
                        state: data.state,
                        level: data.level,
                        updated: data.updated);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
