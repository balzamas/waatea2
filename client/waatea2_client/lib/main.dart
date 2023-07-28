import 'package:flutter/material.dart';

import './screens/login.dart';
import './screens/signup.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Django',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
      },
    );
  }
}
