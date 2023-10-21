import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:waatea2_client/models/game_model.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/lineuppos_model.dart';
import '../globals.dart' as globals;

Icon returnStateIcon(int state) {
  switch (state) {
    case 1:
      return const Icon(
        Icons.thumb_down_alt_outlined,
        color: Colors.red,
      );
    case 2:
      return const Icon(
        Icons.help_outline,
        color: Colors.orange,
      );
    case 3:
      return const Icon(
        Icons.thumb_up_alt_outlined,
        color: Colors.green,
      );
    default:
      return const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
      );
  }
}

Future<List<GameModel>> getGameList(String season, int dayoftheyear) async {
  //Get games
  final response = await http.get(
      Uri.parse(
          "${globals.URL_PREFIX}/api/games_current/filter?club=${globals.clubId}&season=${season}&dayofyear=${dayoftheyear}"),
      headers: {'Authorization': 'Token ${globals.token}'});

  String responseBody = utf8.decode(response.bodyBytes);

  final items = json.decode(responseBody).cast<Map<String, dynamic>>();
  List<GameModel> games = items.map<GameModel>((json) {
    return GameModel.fromJson(json);
  }).toList();

  return games;
}

Future<List<LineUpPosModel>> getLineUp(String gameid) async {
  //Get players
  final responsePlayer = await http.get(
      Uri.parse("${globals.URL_PREFIX}/api/lineupposes?game=${gameid}"),
      headers: {'Authorization': 'Token ${globals.token}'});

  String responseBody = utf8.decode(responsePlayer.bodyBytes);
  final itemsPlayers = json.decode(responseBody).cast<Map<String, dynamic>>();
  List<LineUpPosModel> players = itemsPlayers.map<LineUpPosModel>((json) {
    return LineUpPosModel.fromJson(json);
  }).toList();

  return players;
}
