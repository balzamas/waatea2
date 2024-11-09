import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:waatea2_client/models/user_model.dart';
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
  late String _token = '';

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndLogin();
  }

  void _loadCredentialsAndLogin() {
    _loadCredentials().then((_) {
      if (_token.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          _login_process(_token, _usernameController.text.toLowerCase());
        });
      }
    });
  }

  Future<void> _loadCredentials() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = sharedPreferences.getString('email') ?? '';
      _passwordController.text = sharedPreferences.getString('password') ?? '';
      _token = sharedPreferences.getString('token') ?? '';
    });
  }

  Future<void> _login_process(String token, String username) async {
    final http.Response response2 = await http.get(
        Uri.parse('${globals.URL_PREFIX}/api/users/filter?email=$username'),
        headers: {'Authorization': 'Token $token'});

    if (response2.statusCode == 200) {
      String clubid = json.decode(response2.body)[0]['club']['pk'];
      int userid = json.decode(response2.body)[0]['pk'];

      String responseBody = utf8.decode(response2.bodyBytes);

      final itemsUser = json.decode(responseBody).cast<Map<String, dynamic>>();
      List<UserModel> users = itemsUser.map<UserModel>((json) {
        return UserModel.fromJson(json);
      }).toList();

      final responseCurrentseason = await http.get(
          Uri.parse(
              "${globals.URL_PREFIX}/api/currentseason/filter?club=$clubid"),
          headers: {'Authorization': 'Token $token'});

      final itemsCurrentseason =
          json.decode(responseCurrentseason.body).cast<Map<String, dynamic>>();
      List<CurrentSeasonModel> currentseason =
          itemsCurrentseason.map<CurrentSeasonModel>((json) {
        return CurrentSeasonModel.fromJson(json);
      }).toList();

      String season = currentseason[0].season;

      // Navigate to the next screen (you can go to the home screen here)
      globals.playerId = userid;
      globals.clubId = clubid;
      globals.seasonID = season;
      globals.token = token;
      globals.player = users[0];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(initialIndex: 1),
        ),
      );
    }
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

        sharedPreferences.setString('token', token);

        //Final login
        _login_process(token, username.toLowerCase());
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to log in.\n\nError:\n${response.body}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Failed to log in.\n\nError:\n$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      // Error occurred while making the API call
      print('Error: $e');
      // TODO: Show error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode:
            FocusNode(), // Create a focus node to capture keyboard events
        onKey: (event) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _login(); // Call _login() when Enter key is pressed
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Login')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration:
                      const InputDecoration(labelText: 'Username/Email'),
                  onSubmitted: (_) =>
                      _login(), // Call _login() when Enter key is pressed
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSubmitted: (_) =>
                      _login(), // Call _login() when Enter key is pressed
                ),
                const SizedBox(height: 32),
                Focus(
                  autofocus: true,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 55),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
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
        ));
  }
}
