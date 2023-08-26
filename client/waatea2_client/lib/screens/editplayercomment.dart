import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/home.dart';
import '../globals.dart' as globals;
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import '../helper.dart';

class EditPlayerComment extends StatefulWidget {
  final UserModel user;

  const EditPlayerComment({required this.user});

  @override
  _EditPlayerCommentState createState() => _EditPlayerCommentState();
}

class _EditPlayerCommentState extends State<EditPlayerComment> {
  bool _isPlaying = false;
  int _selectedLevel = 1;
  int _selectedAbonnement = 0;
  QuillController _controller = QuillController.basic();

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.user.profile.isPlaying;
    _selectedLevel = widget.user.profile.level;
    _selectedAbonnement = widget.user.profile.abonnement;

    final List<dynamic> operations = json.decode(widget.user.profile.comment);
    final Delta delta = Delta.fromJson(operations);

    if (delta.isNotEmpty) {
      _controller = QuillController(
        document: Document.fromDelta(delta),
        selection: TextSelection.collapsed(offset: 0),
      );
    } else {
      // Create an empty document
      _controller = QuillController.basic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 500,
              height: 600,
              child: Column(
                children: [
                  QuillToolbar.basic(controller: _controller),
                  Expanded(
                    child: Container(
                      child: QuillEditor.basic(
                        controller: _controller,
                        readOnly: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                final Map<String, dynamic> body = {
                  'comment': jsonEncode(
                    _controller.document.toDelta().toJson(),
                  ),
                };

                final http.Response response = await http.patch(
                  Uri.parse(
                    '${globals.URL_PREFIX}/api/user-profile/${widget.user.pk}/',
                  ),
                  headers: {
                    'Authorization': 'Token ${globals.token}',
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: json.encode(body),
                );
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyHomePage(initialIndex: 5),
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
