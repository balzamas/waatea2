import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      data.name,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
