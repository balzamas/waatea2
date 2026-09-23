import 'dart:convert';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/game_model.dart';

import '../globals.dart' as globals;
import '../models/team_model.dart';
import '../widgets/game_row.dart';

class ShowGames extends StatefulWidget {
  const ShowGames({super.key});

  @override
  State<ShowGames> createState() => ShowGamesState();
}

class ShowGamesState extends State<ShowGames> {
  late Future<List<GameModel>> games;
  final availabilityListKey = GlobalKey<ShowGamesState>();

  List<TeamModel> teams = [];

  @override
  void initState() {
    super.initState();

    games = getGameList();
    loadTeams();
  }

  Future<void> loadTeams() async {
    final response = await http.get(
      Uri.parse(
        '${globals.URL_PREFIX}/api/teams/filter?club=${globals.clubId}',
      ),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (response.statusCode != 200) {
      return;
    }

    final responseBody = utf8.decode(response.bodyBytes);
    final List<dynamic> teamData = json.decode(responseBody);

    if (!mounted) {
      return;
    }

    setState(() {
      teams = teamData.map((team) => TeamModel.fromJson(team)).toList();
    });
  }

  Future<List<GameModel>> getGameList() async {
    final response = await http.get(
      Uri.parse(
        '${globals.URL_PREFIX}/api/games_current/filter'
        '?club=${globals.clubId}',
      ),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Could not load games (${response.statusCode})');
    }

    final responseBody = utf8.decode(response.bodyBytes);

    final items = json.decode(responseBody).cast<Map<String, dynamic>>();

    return items.map<GameModel>((json) => GameModel.fromJson(json)).toList();
  }

  void _refreshGames() {
    setState(() {
      games = getGameList();
    });
  }

  TeamModel? _findTeam(String id) {
    for (final team in teams) {
      if (team.id == id) {
        return team;
      }
    }

    return null;
  }

  Future<void> _showAddGameDialog() async {
    TeamModel? selectedHomeTeam;
    TeamModel? selectedAwayTeam;

    DateTime selectedDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      15,
      0,
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Game'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<TeamModel>(
                      initialValue: selectedHomeTeam,
                      decoration: const InputDecoration(labelText: 'Home Team'),
                      items:
                          teams.map((team) {
                            return DropdownMenuItem<TeamModel>(
                              value: team,
                              child: Text(team.name),
                            );
                          }).toList(),
                      onChanged: (TeamModel? value) {
                        setDialogState(() {
                          selectedHomeTeam = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<TeamModel>(
                      initialValue: selectedAwayTeam,
                      decoration: const InputDecoration(labelText: 'Away Team'),
                      items:
                          teams.map((team) {
                            return DropdownMenuItem<TeamModel>(
                              value: team,
                              child: Text(team.name),
                            );
                          }).toList(),
                      onChanged: (TeamModel? value) {
                        setDialogState(() {
                          selectedAwayTeam = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );

                        if (pickedDate == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Text(
                            '${selectedDateTime.toLocal()}'.split(' ')[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );

                        if (pickedTime == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 10),
                          Text(
                            TimeOfDay.fromDateTime(
                              selectedDateTime,
                            ).format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      selectedHomeTeam == null || selectedAwayTeam == null
                          ? null
                          : () async {
                            final response = await http.post(
                              Uri.parse('${globals.URL_PREFIX}/api/game/'),
                              headers: {
                                'Authorization': 'Token ${globals.token}',
                                'Content-Type': 'application/json',
                              },
                              body: json.encode({
                                'home': selectedHomeTeam!.id,
                                'away': selectedAwayTeam!.id,
                                'date':
                                    selectedDateTime.toUtc().toIso8601String(),
                                'season': globals.seasonID,
                                'club': globals.clubId,
                              }),
                            );

                            if (!mounted) {
                              return;
                            }

                            if (response.statusCode == 201) {
                              Navigator.of(dialogContext).pop();

                              _refreshGames();
                            } else {
                              _showError('Could not create game.', response);
                            }
                          },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditGameDialog(GameModel game) async {
    if (teams.isEmpty) {
      await loadTeams();
    }

    if (!mounted) {
      return;
    }

    TeamModel? selectedHomeTeam = _findTeam(game.homeId);
    TeamModel? selectedAwayTeam = _findTeam(game.awayId);

    DateTime selectedDateTime = DateTime.parse(game.date).toLocal();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Edit Game'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<TeamModel>(
                      initialValue: selectedHomeTeam,
                      decoration: const InputDecoration(labelText: 'Home Team'),
                      items:
                          teams.map((team) {
                            return DropdownMenuItem<TeamModel>(
                              value: team,
                              child: Text(team.name),
                            );
                          }).toList(),
                      onChanged: (TeamModel? value) {
                        setDialogState(() {
                          selectedHomeTeam = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<TeamModel>(
                      initialValue: selectedAwayTeam,
                      decoration: const InputDecoration(labelText: 'Away Team'),
                      items:
                          teams.map((team) {
                            return DropdownMenuItem<TeamModel>(
                              value: team,
                              child: Text(team.name),
                            );
                          }).toList(),
                      onChanged: (TeamModel? value) {
                        setDialogState(() {
                          selectedAwayTeam = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );

                        if (pickedDate == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Text(
                            '${selectedDateTime.toLocal()}'.split(' ')[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );

                        if (pickedTime == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 10),
                          Text(
                            TimeOfDay.fromDateTime(
                              selectedDateTime,
                            ).format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final deleted = await _confirmAndDeleteGame(game);

                    if (!mounted) {
                      return;
                    }

                    if (deleted) {
                      Navigator.of(dialogContext).pop();
                      _refreshGames();
                    }
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      selectedHomeTeam == null || selectedAwayTeam == null
                          ? null
                          : () async {
                            final response = await http.patch(
                              Uri.parse(
                                '${globals.URL_PREFIX}'
                                '/api/game/${game.pk}/',
                              ),
                              headers: {
                                'Authorization': 'Token ${globals.token}',
                                'Content-Type': 'application/json',
                              },
                              body: json.encode({
                                'home': selectedHomeTeam!.id,
                                'away': selectedAwayTeam!.id,
                                'date':
                                    selectedDateTime.toUtc().toIso8601String(),
                              }),
                            );

                            if (!mounted) {
                              return;
                            }

                            if (response.statusCode == 200) {
                              Navigator.of(dialogContext).pop();

                              _refreshGames();
                            } else {
                              _showError('Could not update game.', response);
                            }
                          },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmAndDeleteGame(GameModel game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext confirmationContext) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text(
            'Delete ${game.home} - ${game.away}?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(confirmationContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(confirmationContext).pop(true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    final response = await http.delete(
      Uri.parse('${globals.URL_PREFIX}/api/game/${game.pk}/'),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (response.statusCode == 204) {
      return true;
    }

    if (mounted) {
      _showError('Could not delete game.', response);
    }

    return false;
  }

  void _showError(String message, http.Response response) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message (${response.statusCode})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: const Text('Game editor', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddGameDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<GameModel>>(
        future: games,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<GameModel>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load games.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final gameList = snapshot.data ?? <GameModel>[];

          if (gameList.isEmpty) {
            return const Center(child: Text('No upcoming games.'));
          }

          return ListView.builder(
            itemCount: gameList.length,
            itemBuilder: (BuildContext context, int index) {
              final data = gameList[index];

              return GameRow(
                gameId: data.pk,
                game: '${data.home} - ${data.away}',
                gameDate: data.date,
                dayofyear: data.dayofyear,
                season: data.season,
                onTap: () {
                  _showEditGameDialog(data);
                },
              );
            },
          );
        },
      ),
    );
  }
}
