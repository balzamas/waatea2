import 'package:flutter/material.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/game_model.dart';
import 'package:waatea2_client/models/lineuppos_model.dart';
import 'package:waatea2_client/screens/showlineup.dart';
import '../globals.dart' as globals;
import '../screens/showavailabilitydetail.dart';

class ShowAvailabilityRow extends StatefulWidget {
  final String gameId;
  final String game;
  final String gameDate;
  final int dayofyear;
  final String season;
  final int isAvailable;
  final int isNotAvailable;
  final int isMaybe;
  final int isNotSet;

  const ShowAvailabilityRow({
    Key? key,
    required this.gameId,
    required this.game,
    required this.gameDate,
    required this.dayofyear,
    required this.season,
    required this.isAvailable,
    required this.isNotAvailable,
    required this.isMaybe,
    required this.isNotSet,
  }) : super(key: key);

  @override
  _ShowAvailabilityRowState createState() => _ShowAvailabilityRowState();
}

class _ShowAvailabilityRowState extends State<ShowAvailabilityRow> {
  int state = 0;
  String availabilityId = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          if (globals.player.profile.permission > 0) {
            // Navigate to the ShowAvailabilityDetail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowAvailabilityDetail(
                  widget.gameId,
                  widget.game,
                  widget.gameDate,
                  widget.dayofyear,
                  widget.season,
                  widget.isAvailable,
                  widget.isNotAvailable,
                  widget.isMaybe,
                  widget.isNotSet,
                ),
                // Pass any other necessary parameters to ShowAvailabilityDetail constructor
              ),
            );
          } else {
            Future<List<GameModel>> games =
                getGameList(widget.season, widget.dayofyear);
            String team1Title = "";
            String team2Title = "";
            String team1id = "";
            String team2id = "";
            bool isPublished = false;
            //This is ugly bullshit
            games.then((gameList) async {
              if (gameList.isNotEmpty) {
                team1Title =
                    "${gameList[0].home} - ${gameList[0].away}"; // Set the title
                team1id = gameList[0].pk;
                isPublished = gameList[0].lineup_published;
              }
              if (gameList.length > 1) {
                team2Title =
                    "${gameList[1].home} - ${gameList[1].away}"; // Set the title

                team2id = gameList[1].pk;
              }

              if (isPublished) {
                final team1Lineup =
                    await getLineUp(team1id); // Load the lineup for team 1
                final team2Lineup =
                    await getLineUp(team2id); // Load the lineup for team 2

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowLineUp(
                      team1Title: team1Title,
                      team1Lineup: team1Lineup,
                      team2Title: team2Title,
                      team2Lineup: team2Lineup,
                    ),
                  ),
                );
              }
            });
          }
        },
        child: Container(
          color: const Color.fromARGB(255, 245, 245, 245),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.game,
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 1.5),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Add a row to display the total availability
              Row(
                children: [
                  // Date
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${DateTime.parse(widget.gameDate).day}.${DateTime.parse(widget.gameDate).month}.${DateTime.parse(widget.gameDate).year}",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                    fontSize: 18,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Icon and count for "Available"
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          radius: 25.0,
                          child: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.green,
                            radius: 20.0,
                            child: Text(widget.isAvailable.toString(),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon and count for "Not Available"
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          radius: 25.0,
                          child: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.red,
                            radius: 20.0,
                            child: Text(widget.isNotAvailable.toString(),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon and count for "Maybe"
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          radius: 25.0,
                          child: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.orange,
                            radius: 20.0,
                            child: Text(widget.isMaybe.toString(),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon and count for "Not Set"
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          radius: 25.0,
                          child: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.grey,
                            radius: 20.0,
                            child: Text(widget.isNotSet.toString(),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
