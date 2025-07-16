import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GameRow extends StatefulWidget {
  final String gameId;
  final String game;
  final String gameDate;
  final int dayofyear;
  final String season;

  const GameRow({
    Key? key,
    required this.gameId,
    required this.game,
    required this.gameDate,
    required this.dayofyear,
    required this.season,
  }) : super(key: key);

  @override
  _GameRowState createState() => _GameRowState();
}

class _GameRowState extends State<GameRow> {
  int state = 0;
  String availabilityId = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final formatterTime = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {},
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
                          "${widget.game} // ${formatterTime.format(DateTime.parse(widget.gameDate).toLocal())}",
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

                  // Icon and count for "Not Available"

                  // Icon and count for "Maybe"

                  // Icon and count for "Not Set"
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
