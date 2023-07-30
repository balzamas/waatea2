import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;
import '../screens/showavailabilitydetail.dart';

class ShowAvailabilityRow extends StatefulWidget {
  final String gameId;
  final String game;
  final String date;
  final String token;
  final String clubId;
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
    required this.date,
    required this.token,
    required this.clubId,
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

  Future<void> _submitMutation(
    BuildContext context,
    String gameId,
    int state,
    String token,
  ) async {
    //ToDo: open details
  }

  @override
  Widget build(BuildContext context) {
    Icon iconAvailable = const Icon(
      Icons.thumb_up_alt_outlined,
      color: Colors.green,
    );

    Icon iconNotAvailable = const Icon(
      Icons.thumb_down_alt_outlined,
      color: Colors.red,
    );

    Icon iconMaybe = const Icon(
      Icons.question_mark,
      color: Colors.orange,
    );

    Icon iconNotSet = const Icon(
      Icons.warning_amber_rounded,
      color: Colors.red,
    );

    return Padding(
        padding: const EdgeInsets.all(18.0),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Navigate to the ShowAvailabilityDetail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowAvailabilityDetail(
                    widget.token,
                    widget.clubId,
                    widget.gameId,
                    widget.game,
                    widget.date,
                    widget.dayofyear,
                    widget.season),
                // Pass any other necessary parameters to ShowAvailabilityDetail constructor
              ),
            );
          },
          child: Container(
            color: Color.fromARGB(255, 245, 245, 245),
            child: Row(
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
                      Text(
                        widget.date,
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                iconAvailable,
                Expanded(
                  flex: 1,
                  child: Text(widget.isAvailable.toString(),
                      textAlign: TextAlign.left,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 2.0)),
                ),
                iconNotAvailable,
                Expanded(
                  flex: 1,
                  child: Text(widget.isNotAvailable.toString(),
                      textAlign: TextAlign.left,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 2.0)),
                ),
                iconMaybe,
                Expanded(
                  flex: 1,
                  child: Text(widget.isMaybe.toString(),
                      textAlign: TextAlign.left,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 2.0)),
                ),
                iconNotSet,
                Expanded(
                  flex: 1,
                  child: Text(widget.isNotSet.toString(),
                      textAlign: TextAlign.left,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 2.0)),
                ),
              ],
            ),
          ),
        ));
  }
}
