import 'package:flutter/material.dart';
import 'package:waatea2_client/screens/links.dart';
import 'package:waatea2_client/screens/showattendance.dart';
import 'package:waatea2_client/screens/showplayers.dart';
import 'package:waatea2_client/screens/training_demo.dart';
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
                const NavigationRailDestination(
                  icon: Icon(Icons.sports_rugby_outlined),
                  label: Text('Set Availabilities'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.fitness_center),
                  label: Text('Set Training Attendance'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  label: Text('Show Availabilities'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.link),
                  label: Text('Links'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('User Profile'),
                ),
                if (globals.player.profile.permission >= 1)
                  const NavigationRailDestination(
                    icon: Icon(Icons.recent_actors_outlined),
                    label: Text('Show Training Attendance'),
                  ),
                if (globals.player.profile.permission >= 1)
                  const NavigationRailDestination(
                    icon: Icon(Icons.face),
                    label: Text('Show Players'),
                  ),
                const NavigationRailDestination(
                  icon: Icon(Icons.face),
                  label: Text('Show Players'),
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
        return const SetAttendance();
      case 2:
        return ShowAvailability();
      case 3:
        return ShowLinks();
      case 4:
        return UserProfile();
      case 5:
        return ShowAttendance();
      case 6:
        return ShowPlayers();
      case 7:
        return ReorderableListScreen();

      default:
        return Container();
    }
  }
}
