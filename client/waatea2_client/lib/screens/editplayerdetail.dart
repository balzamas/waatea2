import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:waatea2_client/models/classification_model.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/home.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;

import '../helper.dart';

class EditPlayerDetail extends StatefulWidget {
  final UserModel user;

  const EditPlayerDetail({required this.user});

  @override
  _EditPlayerDetailState createState() => _EditPlayerDetailState();
}

class _EditPlayerDetailState extends State<EditPlayerDetail> {
  bool _isPlaying = false;
  int _selectedLevel = 1;
  int _selectedAbonnement = 0;
  ClassificationModel? _selectedClassification; // Initialize as null
  List<ClassificationModel> classificationOptions = [];

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.user.profile.isPlaying;
    _selectedLevel = widget.user.profile.level;
    _selectedAbonnement = widget.user.profile.abonnement;
    //_selectedClassification = widget.user.profile.classification;

    // Fetch and populate classification options
    fetchClassifications().then((classifications) {
      setState(() {
        classificationOptions = classifications;
        if (widget.user.profile.classification != null) {
          // If the classification is not empty, set it based on the user's profile
          _selectedClassification = classificationOptions.firstWhere(
            (classification) =>
                classification.pk == widget.user.profile.classification!.pk,
            // Set to null when no match is found
          );
        } else {
          // If the classification is empty, set it to null
          _selectedClassification = null;
        }
      });
    });
  }

  Future<List<ClassificationModel>> fetchClassifications() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/classifications/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => ClassificationModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load classifications');
    }
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
    for (var i = 0; i < 5; i++) {
      itemsAbonnement.add(DropdownMenuItem(
        value: i,
        child: Text(returnAbonnementText(i)),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile for ${widget.user.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Is Playing'),
              value: _isPlaying,
              onChanged: (newValue) {
                setState(() {
                  _isPlaying = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Select Level'),
            DropdownButton<int>(
              value: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
              items: itemsLevel,
            ),
            const SizedBox(height: 16),
            const Text('Classification'),
            DropdownButton<ClassificationModel>(
              value: _selectedClassification,
              onChanged: (value) {
                setState(() {
                  _selectedClassification = value!;
                });
              },
              items: [
                // Add a default "Select Classification" item as the first item
                DropdownMenuItem<ClassificationModel>(
                  value: null,
                  child: const Text('Select Classification'),
                ),
                ...classificationOptions.map((classification) {
                  return DropdownMenuItem<ClassificationModel>(
                    value: classification,
                    child: Text(classification.name),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                final Map<String, dynamic> body = {
                  'is_playing': _isPlaying,
                  'level': _selectedLevel,
                  'abonnement': _selectedAbonnement,
                  'classification': _selectedClassification?.pk,
                };

                final http.Response response = await http.patch(
                  Uri.parse(
                      '${globals.URL_PREFIX}/api/user-profile/${widget.user.email}/'),
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
                    builder: (_) => MyHomePage(initialIndex: 6),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
