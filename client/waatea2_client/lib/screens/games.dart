import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/game_model.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/showavailability_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';

import '../widgets/game_row.dart';
import '../widgets/showavailability_row.dart';
import 'home.dart';

class ShowGames extends StatefulWidget {
  ShowGames();
  @override
  ShowGamesState createState() => ShowGamesState();
}

class ShowGamesState extends State<ShowGames> {
  late Future<List<GameModel>> games;
  final availabilityListKey = GlobalKey<ShowGamesState>();
  List<TeamModel> teams = []; // List to store loaded teams

  @override
  void initState() {
    super.initState();
    loadTeams();
    games = getGameList();
  }

  Future<void> loadTeams() async {
    final response = await http.get(
      Uri.parse('${globals.URL_PREFIX}/api/teams/'),
      headers: {'Authorization': 'Token ${globals.token}'},
    );
    String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final List<dynamic> teamData = json.decode(responseBody);
      setState(() {
        teams = teamData.map((team) => TeamModel.fromJson(team)).toList();
      });
    }
  }

  void _showAddGameDialog() {
    TextEditingController dateController = TextEditingController();
    TeamModel? selectedHomeTeam; // Store selected home team
    TeamModel? selectedAwayTeam; // Store selected away team

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDateTime = DateTime(DateTime.now().year,
            DateTime.now().month, DateTime.now().day, 15, 00);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Game'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<TeamModel>(
                      value: selectedHomeTeam,
                      onChanged: (TeamModel? newValue) {
                        setState(() {
                          selectedHomeTeam = newValue!;
                        });
                      },
                      items: teams.map((TeamModel team) {
                        return DropdownMenuItem<TeamModel>(
                          value: team,
                          child: Text(team.name),
                        );
                      }).toList(),
                      decoration: InputDecoration(labelText: 'Home Team'),
                    ),
                    DropdownButtonFormField<TeamModel>(
                      value: selectedAwayTeam,
                      onChanged: (TeamModel? newValue) {
                        setState(() {
                          selectedAwayTeam = newValue!;
                        });
                      },
                      items: teams.map((TeamModel team) {
                        return DropdownMenuItem<TeamModel>(
                          value: team,
                          child: Text(team.name),
                        );
                      }).toList(),
                      decoration: InputDecoration(labelText: 'Away Team'),
                    ),
                    InkWell(
                      onTap: () async {
                        final DateTime? pickedDateTime = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDateTime != null &&
                            pickedDateTime != selectedDateTime) {
                          setState(() {
                            selectedDateTime = DateTime(
                              pickedDateTime.year,
                              pickedDateTime.month,
                              pickedDateTime.day,
                              selectedDateTime.hour,
                              selectedDateTime.minute,
                            );
                          });
                        }
                      },
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Text(
                            "${selectedDateTime.toLocal()}".split(' ')[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              selectedDateTime.year,
                              selectedDateTime.month,
                              selectedDateTime.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      },
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.access_time),
                          const SizedBox(width: 10),
                          Text(
                            TimeOfDay.fromDateTime(selectedDateTime)
                                .format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Add'),
                  onPressed: () async {
                    final response = await http.post(
                      Uri.parse('${globals.URL_PREFIX}/api/game/'),
                      headers: {
                        'Authorization': 'Token ${globals.token}',
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({
                        'home': selectedHomeTeam?.id,
                        'away': selectedAwayTeam?.id,
                        'date': selectedDateTime.toUtc().toIso8601String(),
                        'season': globals.seasonID,
                        'club': globals.clubId
                      }),
                    );

                    if (response.statusCode == 201) {
                      setState(() {
                        games = getGameList();
                      });
                    }

                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyHomePage(initialIndex: 7),
                      ),
                    );
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<GameModel>> getGameList() async {
    //Get games
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/games_current/filter?club=${globals.clubId}"),
        headers: {'Authorization': 'Token ${globals.token}'});

    String responseBody = utf8.decode(response.bodyBytes);

    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
    List<GameModel> games = items.map<GameModel>((json) {
      return GameModel.fromJson(json);
    }).toList();

    return games;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: const Text('Game editor'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () {
              _showAddGameDialog();
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<GameModel>>(
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

                return GameRow(
                    gameId: data.pk,
                    game: data.home + " - " + data.away,
                    gameDate: data.date,
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
