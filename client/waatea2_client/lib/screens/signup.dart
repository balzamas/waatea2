import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  final TextEditingController _mobilephoneController = TextEditingController();

  Future<void> _registerUser() async {
    final String apiUrl = "${globals.URL_PREFIX}/api/register/";

    final Map<String, dynamic> data = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "mobile_phone": _mobilephoneController.text.trim(),
      //ToDo remove hardcoded club
      "club": '2a506873-e57b-4ffb-99a1-7575b1f04aec'
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      // User successfully registered, handle success
      final sharedPreferences = await SharedPreferences.getInstance();
      sharedPreferences.setString('email', _emailController.text);
      sharedPreferences.setString('password', _passwordController.text);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Success"),
          content: Text("User registered successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                // Navigate to the login screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      // Registration failed, handle error
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Error"),
          content: Text("Failed to register user. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _mobilephoneController,
              decoration: InputDecoration(labelText: "Mobile phone"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordConfirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirm Password"),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text ==
                    _passwordConfirmController.text) {
                  _registerUser();
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Password Mismatch"),
                      content: Text("Please make sure both passwords match."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
