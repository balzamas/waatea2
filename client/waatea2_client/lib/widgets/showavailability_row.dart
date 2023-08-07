import 'package:flutter/material.dart';
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
        },
        child: Container(
          color: Color.fromARGB(255, 245, 245, 245),
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
                              Theme.of(context).textTheme.bodyText2?.copyWith(
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
                            backgroundColor: Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.green,
                            radius: 20.0,
                            child: Text(widget.isAvailable.toString(),
                                style: TextStyle(
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
                            backgroundColor: Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.red,
                            radius: 20.0,
                            child: Text(widget.isNotAvailable.toString(),
                                style: TextStyle(
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
                            backgroundColor: Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.orange,
                            radius: 20.0,
                            child: Text(widget.isMaybe.toString(),
                                style: TextStyle(
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
                            backgroundColor: Color.fromARGB(255, 245, 245, 245),
                            foregroundColor: Colors.grey,
                            radius: 20.0,
                            child: Text(widget.isNotSet.toString(),
                                style: TextStyle(
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
