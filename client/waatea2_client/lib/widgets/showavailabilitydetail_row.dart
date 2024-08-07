import 'package:flutter/material.dart';
import 'package:waatea2_client/helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waatea2_client/models/userprofile_model.dart';

class ShowAvailabilityDetailRow extends StatefulWidget {
  final String name;
  final String phonenumber;
  final int state;
  final DateTime? updated;
  final String game;
  final UserProfileModel player;
  final int attendancePercentage;

  const ShowAvailabilityDetailRow(
      {Key? key,
      required this.name,
      required this.phonenumber,
      required this.state,
      required this.updated,
      required this.game,
      required this.player,
      required this.attendancePercentage})
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
    Icon stateIcon = returnStateIcon(widget.state, false);

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
                          .apply(fontSizeFactor: 1),
                    ),
                  ],
                ),
              ),
              stateIcon,
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${widget.attendancePercentage}%",
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
              Expanded(
                  flex: 1,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(widget.player.abonnement?.short ?? '-')
                      ])),
              // const SizedBox(width: 10),
              // Expanded(
              //     flex: 1,
              //     child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.center,
              //         children: [
              //           if (widget.assessment != null &&
              //               widget.assessment?.icon != null)
              //             Padding(
              //                 padding: EdgeInsets.only(
              //                     right: 8.0), // Adjust spacing as needed
              //                 child: Icon(
              //                   IconData(
              //                       int.parse('0x${widget.assessment!.icon}'),
              //                       fontFamily: 'MaterialIcons'),
              //                 ))
              //         ])),
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
                      "${widget.updated?.day}.${widget.updated?.month}.${widget.updated?.year} ${widget.updated?.hour}.${widget.updated?.minute}",
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 0.5),
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
