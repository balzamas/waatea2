// user_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/editplayerdetail.dart';
import 'package:waatea2_client/screens/setavailability.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';

import '../helper.dart';

class ShowPlayerDetail extends StatelessWidget {
  final UserModel user;

  ShowPlayerDetail({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPlayerDetail(user: user),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                returnLevelIcon(user.profile.level),
                const SizedBox(width: 16),
                RandomAvatar(user.name, height: 80, width: 80),
                const SizedBox(width: 16),
                Icon(
                  user.profile.isPlaying ? Icons.check : Icons.close,
                  color: user.profile.isPlaying ? Colors.green : Colors.red,
                ),
              ],
            ),

            // SizedBox(height: 16),
            // Text('Email: ${user.email}'),
            const SizedBox(height: 16),
            Text(returnLevelText(user.profile.level)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.phone),
                Text(user.mobilePhone),
                const SizedBox(width: 16),
                const Icon(Icons.train),
                Text(returnAbonnementText(user.profile.abonnement)),
              ],
            ),
            const SizedBox(height: 22),
            Text('Training attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
            const SizedBox(height: 10),
            Container(
              width: 500, // Replace with your desired width
              height: 30, // Replace with your desired height
              child:
                  ShowPlayerAttendance(user.pk, 10, MainAxisAlignment.center),
            ),
            const SizedBox(height: 22),
            Text('Availability',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
