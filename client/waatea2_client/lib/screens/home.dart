import 'package:flutter/material.dart';
import 'package:waatea2_client/screens/showattendance.dart';
import 'package:waatea2_client/screens/showplayers.dart';
import 'setattendance.dart';
import 'setavailability.dart';
import 'showavailability.dart';
import 'userprofile.dart';
import '../globals.dart' as globals;

class MyHomePage extends StatefulWidget {
  final int initialIndex; // Add this parameter

  MyHomePage({this.initialIndex = 0}); // Provide a default value

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex; // Initialize _currentIndex using initialIndex
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.sports_rugby_outlined),
                  label: Text('Set Availabilities'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.fitness_center),
                  label: Text('Set Training Attendance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  label: Text('Show Availabilities'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.recent_actors_outlined),
                  label: Text('Show Training Attendance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.face),
                  label: Text('Show Players'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('User Profile'),
                ),
              ],
              selectedIndex: _currentIndex,
              onDestinationSelected: (value) {
                setState(() {
                  _currentIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: _getScreenForIndex(_currentIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return SetAvailability(globals.playerId);
      case 1:
        return SetAttendance();
      case 2:
        return ShowAvailability();
      case 3:
        return ShowAttendance();
      case 4:
        return ShowPlayers();
      case 5:
        return UserProfile(globals.token, globals.player.email);
      default:
        return Container();
    }
  }
}
