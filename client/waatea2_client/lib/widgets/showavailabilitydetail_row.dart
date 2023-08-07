import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/screens/showavailabilitydetail.dart';
import '../globals.dart' as globals;

class ShowAvailabilityDetailRow extends StatefulWidget {
  final String name;
  final int level;
  final int state;
  final String updated;

  const ShowAvailabilityDetailRow(
      {Key? key,
      required this.name,
      required this.level,
      required this.state,
      required this.updated})
      : super(key: key);

  @override
  _ShowAvailabilityDetailRowState createState() =>
      _ShowAvailabilityDetailRowState();
}

class _ShowAvailabilityDetailRowState extends State<ShowAvailabilityDetailRow> {
  String availabilityId = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Icon stateIcon;
    if (widget.state == 3) {
      stateIcon = Icon(
        Icons.thumb_up_alt_outlined,
        color: Colors.green,
      );
    } else if (widget.state == 1) {
      stateIcon = Icon(
        Icons.thumb_down_alt_outlined,
        color: Colors.red,
      );
    } else if (widget.state == 2) {
      stateIcon = Icon(
        Icons.help_outline,
        color: Colors.orange,
      );
    } else {
      stateIcon = Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
      );
    }

    Icon levelIcon;
    if (widget.level == 0) {
      levelIcon = Icon(
        Icons.star,
        color: Colors.black,
      );
    } else if (widget.level == 1) {
      levelIcon = Icon(
        Icons.star_border,
        color: Colors.black,
      );
    } else if (widget.level == 2) {
      levelIcon = Icon(
        Icons.lock_clock,
        color: Colors.black,
      );
    } else if (widget.level == 3) {
      levelIcon = Icon(
        Icons.local_bar,
        color: Colors.black,
      );
    } else if (widget.level == 4) {
      levelIcon = Icon(
        Icons.liquor,
        color: Colors.black,
      );
    } else if (widget.level == 5) {
      levelIcon = Icon(
        Icons.pets,
        color: Colors.black,
      );
    } else {
      levelIcon = Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {},
        child: Container(
          color: Color.fromARGB(255, 238, 236, 236),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 1.5),
                    ),
                  ],
                ),
              ),
              Expanded(
                  flex: 1,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [levelIcon])),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Last update:\n" + widget.updated,
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 0.8),
                    ),
                  ],
                ),
              ),
              stateIcon,
            ],
          ),
        ),
      ),
    );
  }
}