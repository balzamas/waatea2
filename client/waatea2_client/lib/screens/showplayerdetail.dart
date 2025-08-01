// user_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/editplayercomment.dart';
import 'package:waatea2_client/screens/editplayerdetail.dart';
import 'package:waatea2_client/screens/historicalgames.dart';
import 'package:waatea2_client/screens/setavailability.dart';
import 'package:waatea2_client/widgets/showplayerattendance.dart';


class ShowPlayerDetail extends StatelessWidget {
  final UserModel user;

  const ShowPlayerDetail({Key? key, 
    required this.user,
  }) : super(key: key);

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
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HistoricalGamesScreen(playerId: user.pk),
                  ));
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
                if (user.profile.classification != null &&
                    user.profile.classification?.icon != null)
                  Padding(
                      padding: const EdgeInsets.only(
                          right: 8.0), // Adjust spacing as needed
                      child: Icon(
                        IconData(
                            int.parse('0x${user.profile.classification!.icon}'),
                            fontFamily: 'MaterialIcons'),
                      )),
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
            if (user.profile.classification != null &&
                user.profile.classification?.icon != null)
              Text(user.profile.classification!.name),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.phone),
                Text(user.profile.mobilePhone),
                const SizedBox(width: 16),
                const Icon(Icons.train),
                if (user.profile.abonnement != null &&
                    user.profile.abonnement?.name != null)
                  Text(user.profile.abonnement!.name),
              ],
            ),
            const SizedBox(height: 22),
            Text('Caps: ${user.caps}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
            const SizedBox(height: 22),
            Text('Training attendance: ${user.attendancePercentage}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
            const SizedBox(height: 10),

            SizedBox(
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
            SizedBox(
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
