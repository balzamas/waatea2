import 'package:flutter/material.dart';
import 'package:waatea2_client/screens/setattendance.dart';

import './screens/login.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waatea 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white), color: Colors.black),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/training': (context) => const SetAttendance(),
      },
    );
  }
}
