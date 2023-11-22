import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/models/lineuppos_model.dart';
import '../globals.dart' as globals;

class ShowLineUp extends StatelessWidget {
  final String team1Title;
  final List<LineUpPosModel> team1Lineup;
  final String team2Title;
  final List<LineUpPosModel> team2Lineup;

  ShowLineUp({
    required this.team1Title,
    required this.team1Lineup,
    required this.team2Title,
    required this.team2Lineup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lineups"),
      ),
      body: ListView(
        children: [
          if (team1Lineup.any((player) => player.player != null))
            _buildTeamLineup(team1Title, team1Lineup),
          if (team2Title != "" &&
              team2Lineup.any((player) => player.player != null))
            SizedBox(height: 20),
          _buildTeamLineup(team2Title, team2Lineup),
        ],
      ),
    );
  }

  Widget _buildTeamLineup(String teamTitle, List<LineUpPosModel> lineup) {
    final filteredLineup =
        lineup.where((player) => player.player != null).toList();

    return filteredLineup.isEmpty
        ? SizedBox() // Return an empty SizedBox if no players are set
        : Column(
            children: [
              Text(
                "$teamTitle",
                style: TextStyle(
                  fontSize: 24, // Set the font size to make the title larger
                  fontWeight: FontWeight.bold, // You can also make it bold
                ),
              ),
              Column(
                children: filteredLineup
                    .map((player) => LineupCard(
                        position: player.position,
                        playerName: player.player!.name,
                        playerId: player.player!.pk))
                    .toList(),
              ),
            ],
          );
  }
}

class LineupCard extends StatelessWidget {
  final int position;
  final String playerName;
  final int playerId;

  LineupCard(
      {required this.position,
      required this.playerName,
      required this.playerId});

  @override
  Widget build(BuildContext context) {
    Color bgcolor = Colors.white;
    if (playerId == globals.playerId) {
      bgcolor = Colors.orange.shade50;
    }
    return Card(
      surfaceTintColor: bgcolor,
      margin: EdgeInsets.zero,
      child: ListTile(
        tileColor: bgcolor,
        leading: Text("${position + 1}"), // Position as leading
        title: Row(
          children: [
            RandomAvatar(playerName,
                height: 20, width: 20), // Avatar afterwards
            SizedBox(
                width: 8), // Add some spacing between the position and avatar
            Text(playerName), // Player name
          ],
        ),
        // subtitle: Row(
        //   children: [
        //     SizedBox(
        //         width: 48), // Add some spacing between the position and avatar
        //     Text("Placeholder bla bla"), // Player name
        //   ],
        // ),
      ),
    );
  }
}
