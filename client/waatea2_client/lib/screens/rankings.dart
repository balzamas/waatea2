import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_avatar/random_avatar.dart';

import '../globals.dart' as globals;
import '../models/user_model.dart';

enum RankingType { trainingPercentage, caps, clubHours }

class ShowRankings extends StatefulWidget {
  const ShowRankings({Key? key}) : super(key: key);

  @override
  _ShowRankingsState createState() => _ShowRankingsState();
}

class _ShowRankingsState extends State<ShowRankings> {
  List<UserModel> users = [];
  RankingType rankingType = RankingType.trainingPercentage;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${globals.URL_PREFIX}/api/users/filter?club=${globals.clubId}'),
        headers: {
          'Authorization': 'Token ${globals.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody);

        setState(() {
          users = data.map((item) => UserModel.fromJson(item)).toList();
          sortUsers();
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load users (status ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading users: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void sortUsers() {
    switch (rankingType) {
      case RankingType.trainingPercentage:
        users.sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
        break;
      case RankingType.caps:
        users.sort((a, b) => b.caps.compareTo(a.caps));
        break;
      case RankingType.clubHours:
        users.sort((a, b) => b.profile.clubHours.compareTo(a.profile.clubHours));
        break;
    }
  }

  void toggleRankingType() {
    setState(() {
      switch (rankingType) {
        case RankingType.trainingPercentage:
          rankingType = RankingType.caps;
          break;
        case RankingType.caps:
          rankingType = RankingType.clubHours;
          break;
        case RankingType.clubHours:
          rankingType = RankingType.trainingPercentage;
          break;
      }
      sortUsers();
    });
  }

  String getAppBarTitle() {
    switch (rankingType) {
      case RankingType.trainingPercentage:
        return 'Training Stars';
      case RankingType.caps:
        return 'Caps';
      case RankingType.clubHours:
        return 'Club Hours';
    }
  }

  IconData getRankingIcon() {
    switch (rankingType) {
      case RankingType.trainingPercentage:
        return Icons.sports_handball;
      case RankingType.caps:
        return Icons.emoji_events;
      case RankingType.clubHours:
        return Icons.access_time;
    }
  }

  String trailingText(UserModel user) {
    switch (rankingType) {
      case RankingType.trainingPercentage:
        return '${user.attendancePercentage}%';
      case RankingType.caps:
        return '${user.caps}';
      case RankingType.clubHours:
        return '${user.profile.clubHours.toStringAsFixed(1)} h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = min(users.length, 20);

    return Scaffold(
      appBar: AppBar(
        title: Text(getAppBarTitle(), style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Switch ranking',
            icon: Icon(getRankingIcon()),
            onPressed: toggleRankingType,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(errorMessage!, textAlign: TextAlign.center),
              ),
            );
          }
          if (users.isEmpty) {
            return const Center(child: Text('No players found.'));
          }

          return ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= users.length) return const SizedBox.shrink();

              final user = users[index];
              final Color playerColor = user.profile.isPlaying ? Colors.black : Colors.red;

              return ListTile(
                leading: RandomAvatar(user.name, height: 40, width: 40),
                title: Text(
                  user.name,
                  style: TextStyle(fontSize: 16, color: playerColor),
                ),
                trailing: Text(
                  trailingText(user),
                  style: TextStyle(fontSize: 16, color: playerColor),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
