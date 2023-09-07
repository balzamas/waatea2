import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:waatea2_client/models/abonnement_model.dart';
import 'package:waatea2_client/models/assessment_model.dart';
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
  AssessmentModel? _selectedAssessment;
  AbonnementModel? _selectedAbonnement;
  ClassificationModel? _selectedClassification; // Initialize as null
  List<ClassificationModel> classificationOptions = [];
  List<AbonnementModel> abonnementOptions = [];
  List<AssessmentModel> assessmentOptions = [];

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.user.profile.isPlaying;

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

    fetchAbonnements().then((abonnements) {
      setState(() {
        abonnementOptions = abonnements;
        if (widget.user.profile.abonnement != null) {
          // If the abonnement is not empty, set it based on the user's profile
          _selectedAbonnement = abonnementOptions.firstWhere(
            (abonnement) => abonnement.pk == widget.user.profile.abonnement!.pk,
            // Set to null when no match is found
          );
        } else {
          // If the abonnement is empty, set it to null
          _selectedAbonnement = null;
        }
      });
    });

    fetchAssessments().then((assessments) {
      setState(() {
        assessmentOptions = assessments;
        if (widget.user.profile.assessment != null) {
          // If the assessment is not empty, set it based on the user's profile
          _selectedAssessment = assessmentOptions.firstWhere(
            (assessment) => assessment.pk == widget.user.profile.assessment!.pk,
            // Set to null when no match is found
          );
        } else {
          // If the assessment is empty, set it to null
          _selectedAssessment = null;
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

  Future<List<AssessmentModel>> fetchAssessments() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/assessments/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => AssessmentModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load assessments');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            DropdownButton<AssessmentModel>(
              value: _selectedAssessment,
              onChanged: (value) {
                setState(() {
                  _selectedAssessment = value!;
                });
              },
              items: [
                // Add a default "Select Classification" item as the first item
                DropdownMenuItem<AssessmentModel>(
                  value: null,
                  child: const Text('Select Level'),
                ),
                ...assessmentOptions.map((assessment) {
                  return DropdownMenuItem<AssessmentModel>(
                    value: assessment,
                    child: Text(assessment.name),
                  );
                }).toList(),
              ],
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
            DropdownButton<AbonnementModel>(
              value: _selectedAbonnement,
              onChanged: (value) {
                setState(() {
                  _selectedAbonnement = value!;
                });
              },
              items: [
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
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                final Map<String, dynamic> body = {
                  'is_playing': _isPlaying,
                  'assessment': _selectedAssessment?.pk,
                  'abo': _selectedAbonnement?.pk,
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
