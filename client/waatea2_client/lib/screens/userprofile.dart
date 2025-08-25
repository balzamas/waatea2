import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/models/abonnement_model.dart';
import 'package:waatea2_client/screens/historicalgames.dart';
import 'package:waatea2_client/screens/home.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:url_launcher/url_launcher.dart'; // url_launcher

import '../globals.dart' as globals;
import '../models/user_model.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);
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
    _getAppVersion();

    fetchAbonnements().then((abonnements) {
      setState(() {
        abonnementOptions = abonnements;
        if (globals.player.profile.abonnement != null) {
          _selectedAbonnement = abonnementOptions.firstWhere(
            (abonnement) =>
                abonnement.pk == globals.player.profile.abonnement!.pk,
          );
        } else {
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

  // ---------- ICS helper functions ----------
  String _playerTrainingIcsHttpsUrl() {
    final base = globals.URL_PREFIX;
    final playerId = globals.playerId;
    final season = globals.seasonID;
    final club = globals.clubId;

    final uri = Uri.parse(base).replace(
      path: "/calendar/player/$playerId/trainings.ics",
      queryParameters: {
        "season": season.toString(),
        "club": club.toString(),
      },
    );
    return uri.toString();
  }

  String _playerTrainingIcsWebcalUrl() {
    final https = _playerTrainingIcsHttpsUrl();
    return https.replaceFirst(RegExp(r'^https?://'), 'webcal://');
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied')),
      );
    }
  }

  Future<void> _launchUrlString(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Was not able to open link: $url')),
        );
      }
    }
  }

  void _showIcsActionsSheet() {
    final httpsUrl = _playerTrainingIcsHttpsUrl();
    final webcalUrl = _playerTrainingIcsWebcalUrl();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.calendar_month),
                title: Text('Training calendar'),
                subtitle: Text('Subscribe ICS or copy link'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in Google calendar (https)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchUrlString(httpsUrl);
                },
                subtitle: Text(httpsUrl,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              ListTile(
                leading: const Icon(Icons.phone_iphone),
                title: const Text('Subscribe on iPhone (webcal)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchUrlString(webcalUrl);
                },
                subtitle: Text(webcalUrl,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy link (https)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyToClipboard(httpsUrl);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ---------- end ICS helpers ----------

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
        _showSuccessDialog();
        final sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setString('password', newPassword);
      } else {
        print('Failed to change password. Status code: ${response.statusCode}');
      }
    } catch (error) {
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
                      const DropdownMenuItem<AbonnementModel>(
                        value: null,
                        child: Text('Select Abonnement'),
                      ),
                      ...abonnementOptions.map((abonnement) {
                        return DropdownMenuItem<AbonnementModel>(
                          value: abonnement,
                          child: Text(abonnement.name),
                        );
                      }),
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
                    String newPhoneNumber = phoneNumberController.text;

                    final Map<String, dynamic> body = {
                      'mobile_phone': newPhoneNumber,
                      'abo': _selectedAbonnement?.pk,
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

                      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: employeeListKey,
      appBar: AppBar(
        title: const Text('User Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'Training ICS',
            onPressed: _showIcsActionsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoricalGamesScreen(playerId: globals.playerId),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            RandomAvatar(globals.player.name, height: 80, width: 80),
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.person),
                const SizedBox(width: 24),
                Text(
                  globals.player.name,
                  style: const TextStyle(fontSize: 17),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.check_box),
                const SizedBox(width: 24),
                Text(
                  "Active: ${globals.player.profile.isPlaying.toString()}",
                  style: const TextStyle(fontSize: 17),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.email),
                const SizedBox(width: 24),
                Text(
                  globals.player.email,
                  style: const TextStyle(fontSize: 17),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.phone),
                const SizedBox(width: 24),
                Text(
                  globals.player.profile.mobilePhone,
                  style: const TextStyle(fontSize: 17),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.category),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (globals.player.profile.classification != null &&
                        globals.player.profile.classification?.name != null)
                      Text(globals.player.profile.classification!.name),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.train),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (globals.player.profile.abonnement != null &&
                        globals.player.profile.abonnement?.name != null)
                      Text(globals.player.profile.abonnement!.name),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.history_edu),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(globals.player.caps.toString()),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                const Icon(Icons.fitness_center),
                const SizedBox(width: 24),
                SizedBox(
                  width: 400,
                  height: 30,
                  child: ShowPlayerAttendance(
                      globals.playerId, 15, MainAxisAlignment.start),
                )
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: _showChangePasswordDialog,
              child: const Text('Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text('Waatea version: ${_version.toString()}'),
          ],
        ),
      ),
    );
  }
}
