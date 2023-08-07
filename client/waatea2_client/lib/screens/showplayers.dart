// user_list_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/showplayerdetail.dart';
import 'dart:convert';
import '../globals.dart' as globals;

class ShowPlayers extends StatefulWidget {
  late final String token;
  late final String clubId;
  late final int userid;

  ShowPlayers(this.token, this.clubId);

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
            '${globals.URL_PREFIX}/api/users/filter?club=${widget.clubId}'),
        headers: {
          'Authorization': 'Token ${widget.token}',
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
            title: Text(user.name),
            subtitle: Text(user.email),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShowPlayerDetail(
                    user: user,
                    clubid: widget.clubId,
                    token: widget.token,
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
