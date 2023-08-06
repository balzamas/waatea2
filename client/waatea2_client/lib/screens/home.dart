import 'package:flutter/material.dart';
import 'package:waatea2_client/screens/showattendance.dart';
import 'package:waatea2_client/screens/showplayers.dart';
import 'setattendance.dart';
import 'setavailability.dart';
import 'showavailability.dart';
import 'userprofile.dart';

class MyHomePage extends StatefulWidget {
  final String token;
  final String user;
  final int userid;
  final String clubid;
  final String season;

  MyHomePage(this.token, this.user, this.clubid, this.userid, this.season);

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
        return SetAvailability(widget.token, widget.clubid, widget.userid);
      case 1:
        return SetAttendance(
            widget.token, widget.clubid, widget.userid, widget.season);
      case 2:
        return ShowAvailability(widget.token, widget.clubid);
      case 3:
        return ShowAttendance(widget.token, widget.season);
      case 4:
        return ShowPlayers(widget.token, widget.clubid);
      case 5:
        return UserProfile(widget.token, widget.user);
      default:
        return Container();
    }
  }
}
