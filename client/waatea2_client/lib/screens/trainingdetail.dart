import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/training_model.dart';
import 'package:waatea2_client/models/trainingpart_model.dart';
import 'package:waatea2_client/screens/home.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import 'package:waatea2_client/models/trainingattendance_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

class TrainingDetailScreen extends StatefulWidget {
  final TrainingAttendanceModel training;

  TrainingDetailScreen({required this.training});

  @override
  _TrainingDetailScreenState createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  QuillController _controllerRemarks = QuillController.basic();
  QuillController _controllerReview = QuillController.basic();
  List<TrainingPart> trainingParts = []; // Replace with TrainingPart list
  TextEditingController _trainingPartController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTrainingPartsForTraining();
    final List<dynamic> operationsRemarks =
        json.decode(widget.training.remarks);
    final Delta deltaRemarks = Delta.fromJson(operationsRemarks);

    if (deltaRemarks.isNotEmpty) {
      _controllerRemarks = QuillController(
        document: Document.fromDelta(deltaRemarks),
        selection: TextSelection.collapsed(offset: 0),
      );
    } else {
      // Create an empty document
      _controllerRemarks = QuillController.basic();
    }

    final List<dynamic> operationsReview = json.decode(widget.training.review);
    final Delta deltaReview = Delta.fromJson(operationsReview);

    if (deltaReview.isNotEmpty) {
      _controllerReview = QuillController(
        document: Document.fromDelta(deltaReview),
        selection: TextSelection.collapsed(offset: 0),
      );
    } else {
      // Create an empty document
      _controllerReview = QuillController.basic();
    }
  }

  Future<void> fetchTrainingPartsForTraining() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${globals.URL_PREFIX}/api/trainingparts/?training=${widget.training.pk}'),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          trainingParts = data.map((item) {
            final trainingPart = TrainingPart.fromJson(item);
            return trainingPart;
          }).toList();
        });
      } else {
        // Handle error if necessary.
        print('API Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle error if necessary.
      print('Error: $error');
    }
  }

  Future<void> _import() async {
    // Fetch the list of available trainings filtered by season and club.
    final response = await http.get(
      Uri.parse(
        '${globals.URL_PREFIX}/api/trainings/?season=${globals.seasonID}&club=${globals.clubId}',
      ),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      List<TrainingModel> availableTrainings = data.map((item) {
        final training = TrainingModel.fromJson(item);
        return training;
      }).toList();

      // Show a dialog to select a training to import its parts.
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select a Training to Import Parts From'),
            content: SingleChildScrollView(
              child: Column(
                children: availableTrainings.map((training) {
                  return ListTile(
                    title:
                        Text(training.date), // Customize the display as needed.
                    onTap: () async {
                      // Fetch the training parts of the selected training.
                      final partsResponse = await http.get(
                        Uri.parse(
                          '${globals.URL_PREFIX}/api/trainingparts/?training=${training.id}',
                        ),
                        headers: {'Authorization': 'Token ${globals.token}'},
                      );

                      if (partsResponse.statusCode == 200) {
                        final List<dynamic> partsData =
                            jsonDecode(partsResponse.body);
                        List<TrainingPart> importedParts =
                            partsData.map((item) {
                          TrainingPart part = TrainingPart.fromJson(item);
                          return part;
                        }).toList();

                        // Add the imported training parts to the current training.
                        setState(() {
                          importedParts.forEach((TrainingPart trainingPart) {
                            // Perform your action on 'trainingPart' here.
                            trainingParts.add(TrainingPart(
                                id: null,
                                trainingId: widget.training.pk,
                                order: trainingPart.order,
                                description: trainingPart.description));
                          });
                        });

                        // Close the dialog.
                        Navigator.of(context).pop();
                      } else {
                        // Handle error if necessary.
                        print('API Error: ${partsResponse.statusCode}');
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } else {
      // Handle error if necessary.
      print('API Error: ${response.statusCode}');
    }
  }

  void _save() async {
    for (int index = 0; index < trainingParts.length; index++) {
      TrainingPart trainingPart = trainingParts[index];

      if (trainingPart.id != null) {
        // This training part already has a primary key (pk), so update it with a PATCH request.
        final response = await http.patch(
          Uri.parse(
              '${globals.URL_PREFIX}/api/trainingpart/${trainingPart.id}/'),
          headers: {'Authorization': 'Token ${globals.token}'},
          body: {
            'description': trainingPart.description,
            'order': index.toString(),
            // Add other fields as needed for updating.
          },
        );

        if (response.statusCode == 200) {
          // Handle success as needed.
          print('Updated training part with id: ${trainingPart.id}');
        } else {
          // Handle error if necessary.
          print('API Error: ${response.statusCode}');
        }
      } else {
        // This training part doesn't have a primary key (pk), so create a new record with a POST request.
        final response = await http.post(
          Uri.parse('${globals.URL_PREFIX}/api/trainingpart/'),
          headers: {'Authorization': 'Token ${globals.token}'},
          body: {
            'description': trainingPart.description,
            'order': index.toString(),
            'training': widget.training.pk
          },
        );

        if (response.statusCode == 201) {
          // Handle success as needed.
          print('Created a new training part');
          // Update the trainingPart with the newly created primary key (pk).
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          //trainingPart.id = responseData['id'];
        } else {
          // Handle error if necessary.
          print('API Error: ${response.statusCode}');
        }
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyHomePage(initialIndex: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Training Detail'),
        actions: [
          // Add a save icon to the AppBar.
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _save();
            },
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _import();
            },
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline_outlined),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _showAddTrainingPartDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display Remarks
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Remarks:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            QuillEditor.basic(
              controller: _controllerRemarks,
              readOnly: true,
            ),

            SizedBox(height: 20), // Adjust spacing as needed
            // Draggable list of drills.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Drills:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
// Draggable list of training parts.
            SizedBox(
              height: 300, // Set the desired height.
              child: ReorderableListView(
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final TrainingPart movedItem =
                        trainingParts.removeAt(oldIndex);
                    trainingParts.insert(newIndex, movedItem);
                  });
                },
                children: trainingParts.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final TrainingPart trainingPart = entry.value;
                  final uniqueKey = Key(
                      '${trainingPart.id}_${index.toString()}'); // Unique key for each training part.
                  return ReorderableDragStartListener(
                      index: index,
                      key: uniqueKey,
                      child: GestureDetector(
                        // Wrap the ListTile with GestureDetector
                        onDoubleTap: () {
                          // Perform the action you want when double-clicked
                          // For example, you can show a dialog or navigate to a new screen.
                          // You can use the `trainingPart` object to access data related to the selected item.
                          _handleDoubleTap(trainingPart);
                        },
                        child: Container(
                          color:
                              index % 2 == 0 ? Colors.white : Colors.grey[200],
                          child: ListTile(
                            key: ValueKey(uniqueKey),
                            title: Text(trainingPart.description),
                            // Add more training part details here.
                          ),
                        ),
                      ));
                }).toList(),
              ),
            ),

            SizedBox(height: 20), // Adjust spacing as needed

            // Display Reviews
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Reviews:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            QuillEditor.basic(
              controller: _controllerReview,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap(TrainingPart trainingPart) {
    // Show the edit dialog directly when double-clicked.
    _showEditTrainingPartDialog(context, trainingPart);
  }

  void _showEditTrainingPartDialog(
      BuildContext context, TrainingPart trainingPart) {
    TextEditingController _editController =
        TextEditingController(text: trainingPart.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit drill'),
          content: Column(
            children: [
              TextField(
                controller: _editController,
                maxLines: null,
                decoration: InputDecoration(labelText: 'Drill description'),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: Text('Remove'),
                    onPressed: () {
                      // Close the edit dialog and remove the training part.
                      Navigator.of(context).pop();
                      _removeTrainingPart(trainingPart);
                    },
                  ),
                  ElevatedButton(
                    child: Text('Save'),
                    onPressed: () {
                      // Update the training part's content with the edited text.
                      setState(() {
                        trainingPart.description = _editController.text;
                      });
                      // Close the edit dialog.
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeTrainingPart(TrainingPart trainingPart) async {
    final String apiUrl =
        '${globals.URL_PREFIX}/api/trainingparts/${trainingPart.id}/';

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (response.statusCode == 204) {
        // The training part was successfully deleted on the server.
        // You can also remove it from your local list.
        setState(() {
          trainingParts.remove(trainingPart);
        });
      } else {
        // Handle error if necessary.
        print('API Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle error if necessary.
      print('Error: $error');
    }
  }

  void _showAddTrainingPartDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Drill'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _trainingPartController,
                  decoration: InputDecoration(labelText: 'Drill Description'),
                  maxLines: null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                final newTrainingPartDescription = _trainingPartController.text;
                if (newTrainingPartDescription.isNotEmpty) {
                  // Create a new TrainingPart and add it to the list
                  final newTrainingPart = TrainingPart(
                    id: null,
                    trainingId: widget.training
                        .pk, // Set the training to the current training
                    description: newTrainingPartDescription,
                    order: 0, // You may set the order appropriately
                  );

                  setState(() {
                    trainingParts.add(newTrainingPart);
                  });

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
