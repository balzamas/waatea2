import 'package:flutter/material.dart';
import 'package:waatea2_client/screens/showattendance.dart';
import 'package:waatea2_client/screens/showplayers.dart';
import 'setattendance.dart';
import 'setavailability.dart';
import 'showavailability.dart';
import 'userprofile.dart';
import '../globals.dart' as globals;

class MyHomePage extends StatefulWidget {
  final String user;

  MyHomePage(this.user);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

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
                  icon: Icon(Icons.list_alt_outlined),
                  label: Text('Show Availabilities'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.playlist_add_check),
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
        return SetAttendance(globals.playerId);
      case 2:
        return ShowAvailability();
      case 3:
        return ShowAttendance();
      case 4:
        return ShowPlayers();
      case 5:
        return UserProfile(globals.token, widget.user);
      default:
        return Container();
    }
  }
}
