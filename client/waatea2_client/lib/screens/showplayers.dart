// user_list_screen.dart

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
          return ListTile(
            leading: RandomAvatar(user.name, height: 40, width: 40),

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
            trailing: returnLevelIcon(user.profile.level), // Add the icon here
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
