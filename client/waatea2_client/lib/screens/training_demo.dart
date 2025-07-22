import 'package:flutter/material.dart';
//import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:waatea2_client/screens/detail_screen.dart';

class ReorderableListScreen extends StatefulWidget {
  const ReorderableListScreen({Key? key}) : super(key: key);

  @override
  _ReorderableListScreenState createState() => _ReorderableListScreenState();
}

class _ReorderableListScreenState extends State<ReorderableListScreen> {
  //QuillController _controller = QuillController.basic();

  List<String> elements = ['Warm up', 'Cool down'];
  List<String> availableItems = [
    'Tackle Technique 1',
    'Tackle Technique 2',
    'Tackling Body Contact',
    'Fitness Circuit 1',
    'Fitness Circuit 2',
    'Fitness Circuit 3',
    'Defence Set Look up',
  ];

  @override
  void initState() {
    super.initState();

   // _controller = QuillController.basic();
  }

  void _showAddItemsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Items'),
          content: SingleChildScrollView(
            child: Column(
              children: availableItems.map((item) {
                return ListTile(
                  title: Text(item),
                  onTap: () {
                    setState(() {
                      elements.add(item);
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _openDetailScreen(BuildContext context, String detailText) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailScreen(detailText: detailText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final docx = Document()
    //   ..insert(0, "Hello, this is some initial text.")
    //   ..insert(28, '\n') // Add a line break
    //   ..insert(29, '• ')
    //   ..insert(30, ' Hello World'); // Add a bullet point

    // _controller.document = docx;

    // final doc = _controller.document.toPlainText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training 19.9.23'),
      ),
      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align children to the left
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the left
            children: [
              // const Text("Remarks:"),
              // Text(doc),
              // const Text("Review:"),
              // Text(doc),
            ],
          ),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final element = elements.removeAt(oldIndex);
                  elements.insert(newIndex, element);
                });
              },
              children: elements.map((element) {
                return ListTile(
                  onTap: () {
                    _openDetailScreen(context, element);
                  },
                  key: Key(element),
                  title: Text(element),
                  leading: const Icon(Icons.bolt),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemsDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
