// user_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/setavailability.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';

class ShowPlayerDetail extends StatelessWidget {
  final UserModel user;

  ShowPlayerDetail({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    String LevelText = "";
    Icon levelIcon = const Icon(
      Icons.warning_amber_rounded,
      color: Colors.red,
    );

    switch (user.profile.level) {
      case 0:
        LevelText = "High performance, performance motivation";
        levelIcon = const Icon(
          Icons.star,
          color: Colors.black,
        );
        break;
      case 1:
        LevelText = "Basic performance, performance motivation";
        levelIcon = const Icon(
          Icons.star_border,
          color: Colors.black,
        );
        break;
      case 2:
        LevelText = "High performance, time deficit";
        levelIcon = const Icon(
          Icons.lock_clock,
          color: Colors.black,
        );
        break;
      case 3:
        LevelText = "High performance, social motivation";
        levelIcon = const Icon(
          Icons.local_bar,
          color: Colors.black,
        );
        break;
      case 4:
        LevelText = "Basic performance, social motivation";
        levelIcon = const Icon(
          Icons.liquor,
          color: Colors.black,
        );
        break;
      case 5:
        LevelText = "Newcomer";
        levelIcon = const Icon(
          Icons.pets,
          color: Colors.black,
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('User Detail'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            levelIcon,
            SizedBox(height: 16),
            Text(user.name),
            SizedBox(height: 16),
            Text('Email: ${user.email}'),
            SizedBox(height: 16),
            Text('Level:'),
            Text(LevelText),
            SizedBox(height: 16),
            Text('Mobile Phone: ${user.mobilePhone}'),
            SizedBox(height: 22),
            Text('Training attendance',
                style: Theme.of(context).textTheme.headline6?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
            SizedBox(height: 10),
            Container(
              width: 500, // Replace with your desired width
              height: 30, // Replace with your desired height
              child:
                  ShowPlayerAttendance(user.pk, 10, MainAxisAlignment.center),
            ),
            SizedBox(height: 22),
            Text('Availability',
                style: Theme.of(context).textTheme.headline6?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
            Container(
              width: 500, // Replace with your desired width
              height: 300, // Replace with your desired height
              child: SetAvailability(user.pk),
            ),
          ],
        ),
      ),
    );
  }
}
