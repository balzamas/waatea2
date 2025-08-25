import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';           // Clipboard
import 'package:url_launcher/url_launcher.dart';  // url_launcher

import '../globals.dart' as globals;

import '../models/showavailability_model.dart';
import '../widgets/showavailability_row.dart';

class ShowAvailability extends StatefulWidget {
  const ShowAvailability({Key? key}) : super(key: key);
  @override
  ShowAvailabilityState createState() => ShowAvailabilityState();
}

class ShowAvailabilityState extends State<ShowAvailability> {
  late Future<List<ShowAvailabilityModel>> games;
  final availabilityListKey = GlobalKey<ShowAvailabilityState>();

  @override
  void initState() {
    super.initState();
    games = getGameList();
  }

  Future<List<ShowAvailabilityModel>> getGameList() async {
    // Get games
    final response = await http.get(
      Uri.parse(
        "${globals.URL_PREFIX}/api/games_current_avail/filter?club=${globals.clubId}",
      ),
      headers: {'Authorization': 'Token ${globals.token}'},
    );

    final responseBody = utf8.decode(response.bodyBytes);
    final items = json.decode(responseBody).cast<Map<String, dynamic>>();
    final games = items.map<ShowAvailabilityModel>((json) {
      return ShowAvailabilityModel.fromJson(json);
    }).toList();

    return games;
  }

  // ---------- ICS helpers (Games / Club) ----------
  String _gamesIcsHttpsUrl() {
    final base = globals.URL_PREFIX; // z.B. https://app.waatea.ch
    final clubId = globals.clubId;   // UUID oder int – egal, kommt in die URL
    final season = globals.seasonID; // UUID oder int

    final uri = Uri.parse(base).replace(
      path: "/calendar/club/$clubId.ics",
      queryParameters: {
        "season": season.toString(),
      },
    );
    return uri.toString();
  }

  String _gamesIcsWebcalUrl() {
    final https = _gamesIcsHttpsUrl();
    return https.replaceFirst(RegExp(r'^https?://'), 'webcal://');
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  Future<void> _launchUrlString(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Was not able to open URL: $url')),
      );
    }
  }

  void _showGamesIcsActionsSheet() {
    final httpsUrl = _gamesIcsHttpsUrl();
    final webcalUrl = _gamesIcsWebcalUrl();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.sports_rugby),
                title: Text('Game calendar'),
                subtitle: Text('Subscribe ICS or copy link'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in Google calendar (https)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchUrlString(httpsUrl);
                },
                subtitle: Text(
                  httpsUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone_iphone),
                title: const Text('Subscribe on iPhone (webcal)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchUrlString(webcalUrl);
                },
                subtitle: Text(
                  webcalUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy link (https)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyToClipboard(httpsUrl);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ---------- end ICS helpers ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: availabilityListKey,
      appBar: AppBar(
        title: const Text('Game list'),
        actions: [
          IconButton(
            tooltip: 'Game-ICS',
            icon: const Icon(Icons.event_note_outlined),
            onPressed: _showGamesIcsActionsSheet,
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<ShowAvailabilityModel>>(
          future: games,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Colors.black);
            }
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                final data = snapshot.data[index];
                return ShowAvailabilityRow(
                  gameId: data.pk,
                  game: "${data.home} - ${data.away}",
                  gameDate: data.date,
                  dayofyear: data.dayofyear,
                  isAvailable: data.isAvailable,
                  isNotAvailable: data.isNotAvailable,
                  isMaybe: data.isMaybe,
                  isNotSet: data.isNotSet,
                  season: data.season,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
