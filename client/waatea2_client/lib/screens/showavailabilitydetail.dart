import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/availability_model.dart';
import '../models/showavailabilitydetail_model.dart';

import '../widgets/showavailabilitydetail_row.dart';

enum SortOption { state, level, updated, name }

class ShowAvailabilityDetail extends StatefulWidget {
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
  SortOption currentSortOption = SortOption.name;
  bool showOnlyAvailableMaybe = false;
  bool sortByNameAscending = true;

  @override
  void initState() {
    super.initState();
    games = getPlayerList();
  }

  Future<List<ShowAvailabilityDetailModel>> getPlayerList() async {
    //Get players
    final response_player = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    final items_players =
        json.decode(response_player.body).cast<Map<String, dynamic>>();
    List<ShowAvailabilityDetailModel> players =
        items_players.map<ShowAvailabilityDetailModel>((json) {
      return ShowAvailabilityDetailModel.fromJson(json);
    }).toList();

    final responseAvail = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/availabilities/filter?dayofyear=${widget.dayofyear}&season=${widget.season}"),
        headers: {'Authorization': 'Token ${globals.token}'});

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
            DateTime updated =
                DateTime.parse(myListFiltered.first.updated).toLocal();
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

  void onSortOptionChanged(SortOption option) {
    setState(() {
      currentSortOption = option;
    });
  }

  void onNameSortChanged() {
    setState(() {
      sortByNameAscending = !sortByNameAscending;
    });
  }

  void onFilterChanged(bool newValue) {
    setState(() {
      showOnlyAvailableMaybe = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: Text(
            "${widget.game} // ${DateTime.parse(widget.gameDate).day}.${DateTime.parse(widget.gameDate).month}.${DateTime.parse(widget.gameDate).year}"),
        actions: [
          PopupMenuButton<SortOption>(
            onSelected: onSortOptionChanged,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: SortOption.state,
                child: Text('Sort by State'),
              ),
              PopupMenuItem(
                value: SortOption.level,
                child: Text('Sort by Level'),
              ),
              PopupMenuItem(
                value: SortOption.updated,
                child: Text('Sort by Updated'),
              ),
              PopupMenuItem(
                value: SortOption.name,
                child: Text('Sort by Name'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(showOnlyAvailableMaybe
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            onPressed: () {
              onFilterChanged(!showOnlyAvailableMaybe);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.green,
                      radius: 20.0,
                      child: Text(widget.isAvailable.toString(),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.orange,
                      radius: 20.0,
                      child: Text(widget.isMaybe.toString(),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.red,
                      radius: 20.0,
                      child: Text(widget.isNotAvailable.toString(),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    radius: 25.0,
                    child: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 245, 245, 245),
                      foregroundColor: Colors.grey,
                      radius: 20.0,
                      child: Text(widget.isNotSet.toString(),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )),
          Expanded(
            child: FutureBuilder<List<ShowAvailabilityDetailModel>>(
              future: games,
              builder: (BuildContext context,
                  AsyncSnapshot<List<ShowAvailabilityDetailModel>> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                // Apply filtering
                var filteredPlayers = snapshot.data!.where((player) {
                  if (showOnlyAvailableMaybe) {
                    return player.state == 2 || player.state == 3;
                  }
                  return true;
                }).toList();

                // Apply sorting
                filteredPlayers.sort((a, b) {
                  switch (currentSortOption) {
                    case SortOption.state:
                      return b.state.compareTo(a.state);
                    case SortOption.level:
                      return a.level.compareTo(b.level);
                    case SortOption.updated:
                      return b.updated.compareTo(a.updated);
                    case SortOption.name: // Added name sorting
                      return sortByNameAscending
                          ? a.name.compareTo(b.name)
                          : b.name.compareTo(a.name);
                  }
                });

                return ListView.builder(
                  itemCount: filteredPlayers.length,
                  itemBuilder: (BuildContext context, int index) {
                    var data = filteredPlayers[index];

                    return ShowAvailabilityDetailRow(
                      name: data.name,
                      state: data.state,
                      level: data.level,
                      updated: data.updated,
                    );
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
