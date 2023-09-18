import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/helper.dart';
import 'package:waatea2_client/models/abonnement_model.dart';
import 'package:waatea2_client/models/historicalgame_model.dart';
import 'package:waatea2_client/screens/historicalgames.dart';
import 'package:waatea2_client/screens/home.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProfile extends StatefulWidget {
  UserProfile();
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<UserProfile> {
  final employeeListKey = GlobalKey<HomeState>();
  String? _version;
  AbonnementModel? _selectedAbonnement;
  List<AbonnementModel> abonnementOptions = [];

  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController abonnementController = TextEditingController();
  @override
  void initState() {
    super.initState();
    //userinfo = getUserInfo();
    _getAppVersion();

    fetchAbonnements().then((abonnements) {
      setState(() {
        abonnementOptions = abonnements;
        if (globals.player.profile.abonnement != null) {
          // If the abonnement is not empty, set it based on the user's profile
          _selectedAbonnement = abonnementOptions.firstWhere(
            (abonnement) =>
                abonnement.pk == globals.player.profile.abonnement!.pk,
            // Set to null when no match is found
          );
        } else {
          // If the abonnement is empty, set it to null
          _selectedAbonnement = null;
        }
      });
    });
  }

  Future<List<AbonnementModel>> fetchAbonnements() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/abonnements/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => AbonnementModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load abonnements');
    }
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
          'Authorization': 'Token ${globals.token}',
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

  void _showEditDialog() {
    TextEditingController phoneNumberController = TextEditingController();
    TextEditingController abonnementController = TextEditingController();

    // Initialize _selectedAbonnement with the value from the user's profile
    phoneNumberController.text = globals.player.profile.mobilePhone;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: phoneNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                  ),
                  const SizedBox(height: 32),
                  const Text('Select Abo'),
                  DropdownButton<AbonnementModel>(
                    value: _selectedAbonnement,
                    onChanged: (value) {
                      setState(() {
                        _selectedAbonnement = value!;
                      });
                    },
                    items: [
                      // Add a default "Select Classification" item as the first item
                      DropdownMenuItem<AbonnementModel>(
                        value: null,
                        child: const Text('Select Abonnement'),
                      ),
                      ...abonnementOptions.map((abonnement) {
                        return DropdownMenuItem<AbonnementModel>(
                          value: abonnement,
                          child: Text(abonnement.name),
                        );
                      }).toList(),
                    ],
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
                  onPressed: () async {
                    // Save the changes to the server and update the UI as needed
                    String newPhoneNumber = phoneNumberController.text;

                    final Map<String, dynamic> body = {
                      'mobile_phone': newPhoneNumber,
                      'abo': _selectedAbonnement?.pk,
                      'assessment': globals.player.profile.assessment?.pk,
                      'classification':
                          globals.player.profile.classification?.pk,
                    };

                    final http.Response response = await http.patch(
                      Uri.parse(
                          '${globals.URL_PREFIX}/api/user-profile/${globals.player.email}/'),
                      headers: {
                        'Authorization': 'Token ${globals.token}',
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: json.encode(body),
                    );

                    final http.Response response2 = await http.get(
                        Uri.parse(
                            '${globals.URL_PREFIX}/api/users/filter?email=${globals.player.email}'),
                        headers: {'Authorization': 'Token ${globals.token}'});

                    if (response2.statusCode == 200) {
                      String responseBody = utf8.decode(response2.bodyBytes);

                      final itemsUser = json
                          .decode(responseBody)
                          .cast<Map<String, dynamic>>();
                      List<UserModel> users = itemsUser.map<UserModel>((json) {
                        return UserModel.fromJson(json);
                      }).toList();

                      globals.player = users[0];

                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(initialIndex: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
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
            child: Column(
          children: [
            const SizedBox(height: 24),
            RandomAvatar(globals.player.name, height: 80, width: 80),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  globals.player.name,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_box),
                title: Text(
                  "Active: ${globals.player.profile.isPlaying.toString()}",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: Text(
                  globals.player.email,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: Text(
                  globals.player.profile.mobilePhone,
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
                      if (globals.player.profile.assessment != null &&
                          globals.player.profile.assessment?.icon != null)
                        Padding(
                            padding: EdgeInsets.only(
                                right: 8.0), // Adjust spacing as needed
                            child: Icon(
                              IconData(
                                  int.parse(
                                      '0x${globals.player.profile.assessment!.icon}'),
                                  fontFamily: 'MaterialIcons'),
                            )),
                      if (globals.player.profile.assessment != null &&
                          globals.player.profile.assessment?.name != null)
                        Text(globals.player.profile.assessment!.name),
                    ],
                  )),
            ),
            Card(
              child: ListTile(
                  leading: const Icon(Icons.train),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (globals.player.profile.abonnement != null &&
                          globals.player.profile.abonnement?.name != null)
                        Text(globals.player.profile.abonnement!.name),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: _showChangePasswordDialog,
              child: const Text('Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        )));
  }
}
