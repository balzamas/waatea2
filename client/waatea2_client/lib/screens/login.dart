import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waatea2_client/screens/signup.dart';
import '../models/currentseason_model.dart';
import 'home.dart';
import '../globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCredentials(); // Load saved email and password
  }

  Future<void> _loadCredentials() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = sharedPreferences.getString('email') ?? '';
      _passwordController.text = sharedPreferences.getString('password') ?? '';
    });
  }

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      // Show an error message if the fields are empty
      return;
    }

    const String apiUrl = "${globals.URL_PREFIX}/api-token-auth/";
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, String> body = {
      'username': username,
      'password': password
    };

    try {
      final http.Response response = await http.post(Uri.parse(apiUrl),
          headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        // User successfully logged in, save login credentials
        final sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.setString('email', _usernameController.text);
        sharedPreferences.setString('password', _passwordController.text);

        // Login successful, extract the token from the response
        String token = json.decode(response.body)['token'];

        // Store the token securely (you can use shared preferences or secure storage)
        // For simplicity, I'm storing it in memory for this example
        // TODO: Store the token securely
        print('Token: $token');

        //Load User
        final http.Response response2 = await http.get(
            Uri.parse('${globals.URL_PREFIX}/api/users/filter?email=$username'),
            headers: {'Authorization': 'Token $token'});

        if (response2.statusCode == 200) {
          String clubid = json.decode(response2.body)[0]['club']['pk'];
          int userid = json.decode(response2.body)[0]['pk'];

          final response_currentseason = await http.get(
              Uri.parse("${globals.URL_PREFIX}/api/currentseason/filter?club=" +
                  clubid),
              headers: {'Authorization': 'Token $token'});

          final items_currentseason = json
              .decode(response_currentseason.body)
              .cast<Map<String, dynamic>>();
          List<CurrentSeasonModel> currentseason =
              items_currentseason.map<CurrentSeasonModel>((json) {
            return CurrentSeasonModel.fromJson(json);
          }).toList();

          String season = currentseason[0].season;

          // Navigate to the next screen (you can go to the home screen here)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MyHomePage(token, username, clubid, userid, season),
            ),
          );
        }
      } else {
        // Login failed, show an error message
        print('Login failed. Status code: ${response.statusCode}');
        // TODO: Show error message to the user
      }
    } catch (e) {
      // Error occurred while making the API call
      print('Error: $e');
      // TODO: Show error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username/Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            SizedBox(height: 55),
            ElevatedButton(
              onPressed: () {
                // Navigate to the login screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(),
                  ),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
