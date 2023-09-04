import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/historicalgame_model.dart';
import 'package:waatea2_client/screens/historicalgames.dart';
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
  int _selectedAbonnement = 0;

  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController abonnementController = TextEditingController();
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

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<DropdownMenuItem<int>>? itemsAbonnement = [];
        for (var i = 0; i < 4; i++) {
          itemsAbonnement.add(DropdownMenuItem(
            value: i,
            child: Text(returnAbonnementText(i)),
          ));
        }
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const Text('Select Abo'),
              DropdownButton<int>(
                value: _selectedAbonnement,
                onChanged: (value) {
                  setState(() {
                    _selectedAbonnement = value!;
                  });
                },
                items: itemsAbonnement,
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
              child: const Text('Save Changes'),
              onPressed: () {
                // Save the changes to the server and update the UI as needed
                String newPhoneNumber = phoneNumberController.text;
                String newAbonnementType = abonnementController.text;

                // Perform the necessary API calls to update the values
                // You may need to add error handling and validation here

                // Update the UI with the new values
                // setState(() {
                //   data.mobilePhone = newPhoneNumber;
                //   // Update abonnement type based on your logic
                //   data.profile.abonnement = newAbonnementType;
                // });

                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHistoricalGamesDialog() async {
    List<HistoricalGameModel> historicalGames = [];

    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/historical_games/filter?player=${globals.playerId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = jsonDecode(responseBody);
      setState(() {
        historicalGames =
            data.map((item) => HistoricalGameModel.fromJson(item)).toList();
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Historical Games'),
          content: ListView.builder(
            itemCount: historicalGames.length,
            itemBuilder: (BuildContext context, int index) {
              var game = historicalGames[index];
              return ListTile(
                title: Text('Played For: ${game.played_for}'),
                subtitle: Text('Played Against: ${game.played_against}'),
                // You can display more information about the game here
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: employeeListKey,
      appBar: AppBar(title: const Text('User Info'), actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Show the edit dialog
            _showEditDialog();
          },
        ),
        IconButton(
          icon: const Icon(Icons.history_edu_rounded),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoricalGamesScreen(playerId: globals.playerId),
                ));
          },
        ),
      ]),
      body: Center(
        child: FutureBuilder<List<UserModel>>(
          future: userinfo,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // By default, show a loading spinner.
            if (!snapshot.hasData)
              return const CircularProgressIndicator(color: Colors.black);
            // Render employee lists
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                var data = snapshot.data[index];
                phoneNumberController.text = data.mobilePhone;
                abonnementController.text =
                    returnAbonnementText(data.profile.abonnement);
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
