import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/availability_model.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/showplayerdetail.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:universal_html/html.dart' as uh;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/game_model.dart';
import '../models/showavailabilitydetail_model.dart';

enum FileGenerationStatus { idle, generating, complete, error }

class ShowRankings extends StatefulWidget {
  ShowRankings();

  @override
  _ShowRankingsState createState() => _ShowRankingsState();
}

class _ShowRankingsState extends State<ShowRankings> {
  List<UserModel> users = [];
  bool showOnlyActive = true;

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
    List<UserModel> filteredUsers =
        users.where((user) => user.profile.isPlaying).toList();

    // Sort the filtered list by attendancePercentage
    filteredUsers.sort(
        (a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));

    return filteredUsers.take(15).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training kings'),
        actions: [],
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
                const SizedBox(width: 10),
                Text(
                  user.attendancePercentage.toString() + "%",
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1, color: playerColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
