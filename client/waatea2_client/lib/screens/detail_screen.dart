import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String detailText;

  DetailScreen({required this.detailText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Screen'),
      ),
      body: Center(
        child: Column(children: [
          const SizedBox(height: 16),
          Text(detailText),
          const SizedBox(height: 16),
          const Text("Link to detailed description"),
          const SizedBox(height: 16),
          const Text("Keywords: Forwards, Line-Outs"),
          const Text("Min. players: 8"),
          const SizedBox(height: 16),
          const Text("Description"),
          const Text("Leute herum hetzen\nDauereinwurf bumm bumm bumm"),
        ]),
      ),
    );
  }
}
