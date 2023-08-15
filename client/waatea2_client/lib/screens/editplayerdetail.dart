import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/showplayers.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;

import '../helper.dart';

class EditPlayerDetail extends StatefulWidget {
  final UserModel user;

  EditPlayerDetail({required this.user});

  @override
  _EditPlayerDetailState createState() => _EditPlayerDetailState();
}

class _EditPlayerDetailState extends State<EditPlayerDetail> {
  bool _isPlaying = false;
  int _selectedLevel =
      1; // Default level, you can adjust this based on your levels

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.user.profile.isPlaying;
    _selectedLevel = widget.user.profile.level;
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>>? itemsx = [];
    for (var i = 0; i < 6; i++) {
      itemsx.add(DropdownMenuItem(
        value: i,
        child: Text(returnLevelText(i)),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile for ${widget.user.name}',
                style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Is Playing'),
              value: _isPlaying,
              onChanged: (newValue) {
                setState(() {
                  _isPlaying = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            Text('Select Level'),
            DropdownButton<int>(
              value: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
              items: itemsx,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final Map<String, dynamic> body = {
                  'is_playing': _isPlaying,
                  'level': _selectedLevel
                };

                final http.Response response = await http.patch(
                  Uri.parse(
                      '${globals.URL_PREFIX}/api/user-profile/${widget.user.pk}/'),
                  headers: {
                    'Authorization': 'Token ${globals.token}',
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: json.encode(body),
                );
                // Save the updated values and navigate back
                // You can implement the saving logic here
                // For example, update the user's profile on a server or database
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowPlayers(),
                  ),
                );
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
