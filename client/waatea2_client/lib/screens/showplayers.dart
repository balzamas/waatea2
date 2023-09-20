import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/showplayerdetail.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import '../globals.dart' as globals;

class ShowPlayers extends StatefulWidget {
  ShowPlayers();

  @override
  _ShowPlayersState createState() => _ShowPlayersState();
}

class _ShowPlayersState extends State<ShowPlayers> {
  List<UserModel> users = [];
  bool showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = jsonDecode(responseBody);
      setState(() {
        users = data.map((item) => UserModel.fromJson(item)).toList();
      });
    }
  }

  List<UserModel> getFilteredUsers() {
    if (showOnlyActive) {
      return users.where((user) => user.profile.isPlaying).toList();
    } else {
      return users;
    }
  }

  void onFilterChanged(bool newValue) {
    setState(() {
      showOnlyActive = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          IconButton(
            icon: Icon(showOnlyActive
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            onPressed: () {
              onFilterChanged(!showOnlyActive);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: getFilteredUsers().length,
        itemBuilder: (context, index) {
          final user = getFilteredUsers()[index];
          Color playerColor = Colors.black;
          if (!user.profile.isPlaying) {
            playerColor = Colors.red;
          }

          return ListTile(
            leading: RandomAvatar(user.name, height: 40, width: 40),
            title: Text(
              user.name,
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(fontSizeFactor: 1, color: playerColor),
            ),
            // subtitle: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Container(
            //       width: 500, // Replace with your desired width
            //       height: 40, // Replace with your desired height
            //       child:
            //           ShowPlayerAttendance(user.pk, 6, MainAxisAlignment.start),
            //     ),
            //   ],
            // ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.profile.classification != null &&
                    user.profile.classification?.icon != null)
                  Padding(
                      padding: EdgeInsets.only(
                          right: 8.0), // Adjust spacing as needed
                      child: Icon(
                        IconData(
                            int.parse('0x${user.profile.classification!.icon}'),
                            fontFamily: 'MaterialIcons'),
                      )),
                if (user.profile.assessment != null &&
                    user.profile.assessment?.icon != null)
                  Padding(
                      padding: EdgeInsets.only(
                          right: 8.0), // Adjust spacing as needed
                      child: Icon(
                        IconData(
                            int.parse('0x${user.profile.assessment!.icon}'),
                            fontFamily: 'MaterialIcons'),
                      )),
                const SizedBox(width: 10),
                Text(
                  user.attendancePercentage.toString() + "%",
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1, color: playerColor),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShowPlayerDetail(
                    user: user,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
