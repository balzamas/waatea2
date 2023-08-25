import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _version;
  @override
  void initState() {
    super.initState();
    userinfo = getUserInfo();
    _getAppVersion();
  }

  void _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    setState(() {
      _version = version;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Password updated successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> changePassword(String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${globals.URL_PREFIX}/api/change-password/'),
        headers: {
          'Authorization': 'Token ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        // Password changed successfully
        _showSuccessDialog();
        final sharedPreferences = await SharedPreferences.getInstance();

        sharedPreferences.setString('password', newPassword);
      } else {
        // Handle API error
        //ToDo: inform user
        print('Failed to change password. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error while changing password: $error');
    }
  }

  void _showChangePasswordDialog() {
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              TextField(
                controller: confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Change Password'),
              onPressed: () {
                String newPassword = newPasswordController.text;
                String confirmPassword = confirmPasswordController.text;

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')),
                  );
                  return;
                }

                changePassword(newPassword);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<UserModel>> getUserInfo() async {
    final response = await http.get(
        Uri.parse(
            "${globals.URL_PREFIX}/api/users/filter?email=${widget.user}"),
        headers: {'Authorization': 'Token ${widget.token}'});

    String responseBody = utf8.decode(response.bodyBytes);
    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
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
            if (!snapshot.hasData) return const CircularProgressIndicator();
            // Render employee lists
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                var data = snapshot.data[index];
                return Column(children: [
                  const SizedBox(height: 24),
                  RandomAvatar(data.name, height: 80, width: 80),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                        data.name,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_box),
                      title: Text(
                        "Active: ${data.profile.isPlaying.toString()}",
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(
                        data.email,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(
                        data.mobilePhone,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                        leading: const Icon(Icons.category),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            returnLevelIcon(data.profile.level),
                            Text(returnLevelText(data.profile.level)),
                          ],
                        )),
                  ),
                  Card(
                    child: ListTile(
                        leading: const Icon(Icons.train),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(returnAbonnementText(data.profile.abonnement)),
                          ],
                        )),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Container(
                        width: 500, // Replace with your desired width
                        height: 30, // Replace with your desired height
                        child: ShowPlayerAttendance(
                            globals.playerId, 15, MainAxisAlignment.start),
                      ),
                    ),
                  ),
                  Text('Waatea version: ${_version.toString()}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: _showChangePasswordDialog,
                    child: const Text('Change Password',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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
