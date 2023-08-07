// user_list_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
        });
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        users = data.map((item) => UserModel.fromJson(item)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          String LevelText = "";
          Icon levelIcon = const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
          );

          switch (user.profile.level) {
            case 0:
              LevelText = "High performance, performance motivation";
              levelIcon = const Icon(
                Icons.star,
                color: Colors.black,
              );
              break;
            case 1:
              LevelText = "Basic performance, performance motivation";
              levelIcon = const Icon(
                Icons.star_border,
                color: Colors.black,
              );
              break;
            case 2:
              LevelText = "High performance, time deficit";
              levelIcon = const Icon(
                Icons.lock_clock,
                color: Colors.black,
              );
              break;
            case 3:
              LevelText = "High performance, social motivation";
              levelIcon = const Icon(
                Icons.local_bar,
                color: Colors.black,
              );
              break;
            case 4:
              LevelText = "Basic performance, social motivation";
              levelIcon = const Icon(
                Icons.liquor,
                color: Colors.black,
              );
              break;
            case 5:
              LevelText = "Newcomer";
              levelIcon = const Icon(
                Icons.pets,
                color: Colors.black,
              );
              break;
          }
          return ListTile(
            title: Text(
              user.name,
              style:
                  DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 500, // Replace with your desired width
                    height: 40, // Replace with your desired height
                    child: ShowPlayerAttendance(
                        user.pk, 6, MainAxisAlignment.start))
              ],
            ),
            trailing: levelIcon, // Add the icon here
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
