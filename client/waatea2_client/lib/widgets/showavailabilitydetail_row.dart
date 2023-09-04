import 'package:flutter/material.dart';
import 'package:waatea2_client/helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/models/userprofile_model.dart';

class ShowAvailabilityDetailRow extends StatefulWidget {
  final String name;
  final String phonenumber;
  final int level;
  final int state;
  final String updated;
  final String game;
  final UserProfileModel player;

  const ShowAvailabilityDetailRow(
      {Key? key,
      required this.name,
      required this.phonenumber,
      required this.level,
      required this.state,
      required this.updated,
      required this.game,
      required this.player})
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
    Icon stateIcon = returnStateIcon(widget.state);

    Icon levelIcon = returnLevelIcon(widget.level);

    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {},
        child: Container(
          color: const Color.fromARGB(255, 238, 236, 236),
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
              stateIcon,
              const SizedBox(width: 40),
              Expanded(
                  flex: 1,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          widget.player.classification?.icon != null
                              ? IconData(
                                  int.parse(
                                      '0x${widget.player.classification!.icon}'),
                                  fontFamily: 'MaterialIcons',
                                )
                              : Icons.highlight_off,
                        )
                      ])),
              const SizedBox(width: 40),
              Expanded(
                  flex: 1,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [levelIcon])),
              Expanded(
                  flex: 1,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            String url =
                                "https://wa.me/${widget.phonenumber}?text=Are you available for ${widget.game}? Please update Waatea!";
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          },
                          child: const Icon(
                            Icons.message,
                            color: Colors.black,
                          ),
                        ),
                      ])),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Last update:\n${widget.updated}",
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
