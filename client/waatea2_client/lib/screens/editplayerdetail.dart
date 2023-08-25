import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/home.dart';
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
  int _selectedLevel = 1;
  int _selectedAbonnement = 0;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.user.profile.isPlaying;
    _selectedLevel = widget.user.profile.level;
    _selectedAbonnement = widget.user.profile.abonnement;
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>>? itemsLevel = [];
    for (var i = 0; i < 6; i++) {
      itemsLevel.add(DropdownMenuItem(
        value: i,
        child: Text(returnLevelText(i)),
      ));
    }
    List<DropdownMenuItem<int>>? itemsAbonnement = [];
    for (var i = 0; i < 4; i++) {
      itemsAbonnement.add(DropdownMenuItem(
        value: i,
        child: Text(returnAbonnementText(i)),
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
              items: itemsLevel,
            ),
            SizedBox(height: 16),
            Text('Select Abo'),
            DropdownButton<int>(
              value: _selectedAbonnement,
              onChanged: (value) {
                setState(() {
                  _selectedAbonnement = value!;
                });
              },
              items: itemsAbonnement,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final Map<String, dynamic> body = {
                  'is_playing': _isPlaying,
                  'level': _selectedLevel,
                  'abonnement': _selectedAbonnement
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
                    builder: (_) => MyHomePage(initialIndex: 5),
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
