import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:waatea2_client/models/link_model.dart';
import 'dart:convert';
import '../globals.dart' as globals;

class ShowLinks extends StatefulWidget {
  ShowLinks();

  @override
  _ShowLinksState createState() => _ShowLinksState();
}

class _ShowLinksState extends State<ShowLinks> {
  List<LinkModel> links = [];

  @override
  void initState() {
    super.initState();
    fetchLinks();
  }

  Future<void> fetchLinks() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/links/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = jsonDecode(responseBody);
      setState(() {
        links = data.map((item) => LinkModel.fromJson(item)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Links'),
      ),
      body: ListView.builder(
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];

          return ListTile(
            leading: Icon(
              IconData(int.parse('0x${link.icon}'),
                  fontFamily: 'MaterialIcons'),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  link.name,
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.5),
                )
              ],
            ),
            onTap: () async {
              await launchUrl(Uri.parse(link.url),
                  mode: LaunchMode.externalApplication);
            },
          );
        },
      ),
    );
  }
}
