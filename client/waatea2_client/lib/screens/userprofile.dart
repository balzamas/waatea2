import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import '../models/user_model.dart';

class UserProfile extends StatefulWidget {
  late final String token;
  late final String user;
  UserProfile(this.token, this.user);
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<UserProfile> {
  late Future<List<UserModel>> userinfo;
  final employeeListKey = GlobalKey<HomeState>();

  @override
  void initState() {
    super.initState();
    userinfo = getUserInfo();
  }

  Future<List<UserModel>> getUserInfo() async {
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/users/filter?email=${widget.user}"),
        headers: {'Authorization': 'Token ${widget.token}'});

    final items = json.decode(response.body).cast<Map<String, dynamic>>();
    List<UserModel> employees = items.map<UserModel>((json) {
      return UserModel.fromJson(json);
    }).toList();

    return employees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: employeeListKey,
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: Center(
        child: FutureBuilder<List<UserModel>>(
          future: userinfo,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // By default, show a loading spinner.
            if (!snapshot.hasData) return CircularProgressIndicator();
            // Render employee lists
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                var data = snapshot.data[index];
                return Column(children: [
                  SizedBox(height: 24),
                  RandomAvatar(data.name, height: 80, width: 80),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text(
                        data.name,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.check_box),
                      title: Text(
                        "Active: ${data.profile.isPlaying.toString()}",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.email),
                      title: Text(
                        data.email,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.phone),
                      title: Text(
                        data.mobilePhone,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                        leading: Icon(Icons.category),
                        title: Column(
                          children: [
                            returnLevelIcon(data.profile.level),
                            Text(returnLevelText(data.profile.level)),
                          ],
                          crossAxisAlignment: CrossAxisAlignment.start,
                        )),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.fitness_center),
                      title: Container(
                        width: 500, // Replace with your desired width
                        height: 30, // Replace with your desired height
                        child: ShowPlayerAttendance(
                            globals.playerId, 15, MainAxisAlignment.start),
                      ),
                    ),
                  ),
                ]);
              },
            );
          },
        ),
      ),
    );
  }
}
