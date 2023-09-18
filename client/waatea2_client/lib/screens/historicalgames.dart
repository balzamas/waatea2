import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/historicalgame_model.dart';
import 'dart:convert';
import '../globals.dart' as globals;

class HistoricalGamesScreen extends StatelessWidget {
  final int playerId;

  HistoricalGamesScreen({required this.playerId});

  Future<List<HistoricalGameModel>> getHistoricalGames() async {
    List<HistoricalGameModel> historicalGames = [];

    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/historical_games/filter?player=${playerId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = jsonDecode(responseBody);

      historicalGames =
          data.map((item) => HistoricalGameModel.fromJson(item)).toList();
    }
    return historicalGames;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoricalGameModel>>(
      future: getHistoricalGames(),
      builder: (BuildContext context,
          AsyncSnapshot<List<HistoricalGameModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching historical games'));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Historical Games'),
          ),
          body: ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (BuildContext context, int index) {
              var game = snapshot.data?[index];
              return ListTile(
                title: Text(
                  '${game?.played_against}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
                subtitle: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${game?.played_for}\n${game?.competition}",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${game?.date != null ? "${DateTime.parse(game!.date!).day}.${DateTime.parse(game.date!).month}.${DateTime.parse(game.date!).year}" : "N/A"}",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pos.: ${game?.position}",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
