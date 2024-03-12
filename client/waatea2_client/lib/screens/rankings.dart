import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';
import '../globals.dart' as globals;
import '../models/user_model.dart';

enum RankingType { trainingPercentage, caps }

class ShowRankings extends StatefulWidget {
  ShowRankings();

  @override
  _ShowRankingsState createState() => _ShowRankingsState();
}

class _ShowRankingsState extends State<ShowRankings> {
  List<UserModel> users = [];
  RankingType rankingType = RankingType.trainingPercentage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse(
          '${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}'),
      headers: {
        'Authorization': 'Token ${globals.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = jsonDecode(responseBody);
      setState(() {
        users = data.map((item) => UserModel.fromJson(item)).toList();
        sortUsers();
      });
    }
  }

  void sortUsers() {
    if (rankingType == RankingType.trainingPercentage) {
      users.sort(
          (a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
    } else {
      users.sort((a, b) => b.caps.compareTo(a.caps));
    }
  }

  void toggleRankingType() {
    setState(() {
      rankingType = rankingType == RankingType.trainingPercentage
          ? RankingType.caps
          : RankingType.trainingPercentage;
      sortUsers();
    });
  }

  String getAppBarTitle() {
    return rankingType == RankingType.trainingPercentage
        ? 'Training Kings'
        : 'Caps';
  }

  @override
  Widget build(BuildContext context) {
    int itemCount =
        rankingType == RankingType.trainingPercentage ? 20 : users.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(getAppBarTitle()),
        actions: [
          IconButton(
            icon: Icon(rankingType == RankingType.trainingPercentage
                ? Icons.fitness_center
                : Icons.sports_handball),
            onPressed: toggleRankingType,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final user = users[index];
          Color playerColor =
              user.profile.isPlaying ? Colors.black : Colors.red;

          return ListTile(
            leading: RandomAvatar(user.name, height: 40, width: 40),
            title: Text(
              user.name,
              style: TextStyle(fontSize: 16, color: playerColor),
            ),
            trailing: Text(
              rankingType == RankingType.trainingPercentage
                  ? '${user.attendancePercentage.toString()}%'
                  : '${user.caps}',
              style: TextStyle(fontSize: 16, color: playerColor),
            ),
          );
        },
      ),
    );
  }
}
