import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:waatea2_client/models/training_model.dart';
import 'package:waatea2_client/models/trainingpart_model.dart';
import 'package:waatea2_client/screens/home.dart';
import 'dart:convert';
import '../globals.dart' as globals;

import 'package:waatea2_client/models/trainingattendance_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:universal_html/html.dart' as uh;

enum FileGenerationStatus { idle, generating, complete, error }

final screenshotController = ScreenshotController();

class TrainingDetailScreen extends StatefulWidget {
  final TrainingAttendanceModel training;
  TrainingDetailScreen({required this.training});

  @override
  _TrainingDetailScreenState createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  List<TrainingPart> trainingParts = []; // Replace with TrainingPart list
  TextEditingController _trainingPartController = TextEditingController();
  FileGenerationStatus generationStatus = FileGenerationStatus.idle;

  @override
  void initState() {
    super.initState();
    fetchTrainingPartsForTraining();
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Training'),
          content: Text('Are you sure you want to delete this training?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _deleteTraining();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTraining() async {
    try {
      final response = await http.delete(
        Uri.parse('${globals.URL_PREFIX}/api/trainings/${widget.training.pk}/'),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (response.statusCode == 204) {
        // Training deleted successfully
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyHomePage(initialIndex: 5),
          ),
        );
      } else {
        // Handle error if necessary.
        print('API Error: ${response.statusCode}');
      }
    } catch (error) {
      // Handle error if necessary.
      print('Error: $error');
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
                  DateTime trainingDate = DateTime.parse(training.date);

                  return ListTile(
                    title: Text(
                        '${trainingDate.day}.${trainingDate.month}.${trainingDate.year}'), // Customize the display as needed.
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
                                description: trainingPart.description,
                                minutes: trainingPart.minutes));
                          });
                        });

                        // Close the dialog.
                        Navigator.of(context).pop();
                        _save();
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
            'minutes': trainingPart.minutes.toString(),
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
            'training': widget.training.pk,
            'minutes': trainingPart.minutes.toString()
          },
        );

        if (response.statusCode == 201) {
          // Handle success as needed.
          print('Created a new training part');
          // Update the trainingPart with the newly created primary key (pk).
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          trainingParts[index].id = responseData['id'];
          //trainingPart.id = responseData['id'];
        } else {
          // Handle error if necessary.
          print('API Error: ${response.statusCode}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime trainingDate = DateTime.parse(widget.training.date);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${trainingDate.day}.${trainingDate.month}.${trainingDate.year}"),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () {
              // Call the save method when the save icon is pressed.
              _generatePDF();
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
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog();
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

            SizedBox(height: 20), // Adjust spacing as needed
            // Draggable list of drills.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Drills:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Screenshot(
              controller: screenshotController, // create a ScreenshotController
// Draggable list of training parts.
              child: Container(
                width: MediaQuery.of(context).size.width - 60,
                child: SizedBox(
                  height: 900, // Set the desired height.
                  child: ReorderableListView(
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final TrainingPart movedItem =
                            trainingParts.removeAt(oldIndex);
                        trainingParts.insert(newIndex, movedItem);
                        _save();
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
                              color: index % 2 == 0
                                  ? Colors.white
                                  : Colors.grey[200],
                              child: ListTile(
                                key: ValueKey(uniqueKey),
                                title: Text(trainingPart.description),
                                leading: Text(trainingPart.minutes.toString()),
                                // Add more training part details here.
                              ),
                            ),
                          ));
                    }).toList(),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20), // Adjust spacing as needed

            // // Display Reviews
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Text(
            //     'Reviews:',
            //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //   ),
            // ),
            // QuillEditor.basic(
            //   controller: _controllerReview,
            //   readOnly: true,
            // ),
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
    TextEditingController _editDescriptionController =
        TextEditingController(text: trainingPart.description);
    TextEditingController _editMinutesController =
        TextEditingController(text: trainingPart.minutes.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Drill'),
          content: Column(
            children: [
              TextField(
                controller: _editDescriptionController,
                maxLines: null,
                decoration: InputDecoration(labelText: 'Drill Description'),
              ),
              TextField(
                controller: _editMinutesController,
                decoration: InputDecoration(labelText: 'Minutes'),
                keyboardType: TextInputType.number, // Ensure numeric input.
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
                      // Update the training part's content with the edited text and minutes.
                      setState(() {
                        trainingPart.description =
                            _editDescriptionController.text;
                        trainingPart.minutes =
                            int.parse(_editMinutesController.text);
                      });
                      // Close the edit dialog.
                      _save();
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

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Training date
              pw.Text('Training: ${widget.training.date}'),
              pw.Divider(),
              // Remarks
              pw.Text('Remarks:'),
              pw.Divider(),
              // Drills
              pw.Row(children: [pw.Text('Drills:')]),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "mins",
                    textAlign: pw.TextAlign.left,
                  ),
                ],
              ),
              pw.Divider(),

              for (var index = 0; index < trainingParts.length; index++)
                pw.Column(
                  children: [
                    pw.Container(
                      color:
                          index % 2 == 0 ? PdfColors.grey200 : PdfColors.white,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            trainingParts[index]
                                .minutes
                                .toString()
                                .padLeft(2, '0'),
                            textAlign: pw.TextAlign.left,
                          ),
                          pw.SizedBox(width: 30),
                          pw.Text(
                            trainingParts[index].description,
                            textAlign: pw.TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    // final file = File('/home/ctrl/training_report.pdf');
    // await file.writeAsBytes(await pdf.save());

    // Open the PDF directly without saving to disk
    saveAndDownloadFile("training.pdf", pdfBytes);
  }

  Future<void> saveAndDownloadFile(String fileName, Uint8List content) async {
    try {
      // Handle file download for web platforms
      final blob = uh.Blob([Uint8List.fromList(content)]);
      final url = uh.Url.createObjectUrlFromBlob(blob);
      final anchor = uh.AnchorElement(href: url)
        ..setAttribute('download', '$fileName')
        ..click();
      uh.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error generating file: $e');
      Navigator.of(context).pop(); // Close the generation status dialog
    }
  }

  void _showAddTrainingPartDialog(BuildContext context) async {
    TextEditingController _addDescriptionController = TextEditingController();
    TextEditingController _addMinutesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Drill'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _addDescriptionController,
                  decoration: InputDecoration(labelText: 'Drill Description'),
                  maxLines: null,
                ),
                TextField(
                  controller: _addMinutesController,
                  decoration: InputDecoration(labelText: 'Minutes'),
                  keyboardType: TextInputType.number, // Ensure numeric input.
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
              onPressed: () async {
                final newTrainingPartDescription =
                    _addDescriptionController.text;
                final newTrainingPartMinutes =
                    int.parse(_addMinutesController.text);

                if (newTrainingPartDescription.isNotEmpty) {
                  // Create a new TrainingPart and add it to the list
                  final newTrainingPart = TrainingPart(
                    id: null,
                    trainingId: widget.training.pk,
                    description: newTrainingPartDescription,
                    order: 0,
                    minutes: newTrainingPartMinutes,
                  );

                  setState(() {
                    trainingParts.add(newTrainingPart);
                  });

                  _save();

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
