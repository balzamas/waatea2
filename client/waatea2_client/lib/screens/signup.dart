import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;
import '../models/club.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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

  final _mobilephoneFormatter = FilteringTextInputFormatter.digitsOnly;

  List<ClubModel> _clubs = [];
  ClubModel? _selectedClub;

  bool _formSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fetchClubs().then((_) {
      // Set the default selected club when clubs are available
      if (_clubs.isNotEmpty) {
        setState(() {
          _selectedClub = _clubs.first;
        });
      }
    });
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegExp.hasMatch(email);
  }

  Future<void> _fetchClubs() async {
    const String apiUrl = "${globals.URL_PREFIX}/api/clubs/allclubs";
    final http.Response response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> clubData = jsonDecode(response.body);
      setState(() {
        _clubs = clubData.map((data) => ClubModel.fromJson(data)).toList();
      });
    } else {
      // Handle error if clubs fetching fails
      print('Failed to fetch clubs.');
    }
  }

  Future<void> _registerUser() async {
    const String apiUrl = "${globals.URL_PREFIX}/api/register/";

    final Map<String, dynamic> data = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "mobile_phone": _mobilephoneController.text.trim(),
      "club": _selectedClub!.pk
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
          title: const Text("Success"),
          content: const Text("User registered successfully!"),
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
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      // Registration failed, handle error
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text(
              "Failed to register user. Please try again.\n\nError:\n${response.body}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name and last name",
                errorText: _formSubmitted && _nameController.text.isEmpty
                    ? "Field is required"
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobilephoneController,
              inputFormatters: [_mobilephoneFormatter],
              decoration: InputDecoration(
                labelText: "Mobile phone (format: 41798257004)",
                errorText: _formSubmitted && _mobilephoneController.text.isEmpty
                    ? "Field is required"
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                errorText: _formSubmitted && _emailController.text.isEmpty
                    ? "Field is required"
                    : _formSubmitted && !_isValidEmail(_emailController.text)
                        ? "Enter a valid email"
                        : null,
              ),
            ),
            const SizedBox(height: 24),
            // DropdownButtonFormField<int>(
            //   value: _selectedSubscription,
            //   onChanged: (int? newValue) {
            //     setState(() {
            //       _selectedSubscription = newValue!;
            //     });
            //   },
            //   items: List<DropdownMenuItem<int>>.generate(4, (index) {
            //     return DropdownMenuItem<int>(
            //       value: index,
            //       child: Text(returnAbonnementText(index)),
            //     );
            //   }),
            //   decoration: InputDecoration(
            //     labelText: "Subscription",
            //     border: OutlineInputBorder(),
            //     errorText: _formSubmitted && _selectedSubscription == null
            //         ? "Field is required"
            //         : null,
            //   ),
            // ),
            // SizedBox(height: 24),
            DropdownButtonFormField<ClubModel>(
              value: _selectedClub,
              onChanged: (ClubModel? newValue) {
                setState(() {
                  _selectedClub = newValue;
                });
              },
              items: _clubs.map((club) {
                return DropdownMenuItem<ClubModel>(
                  value: club,
                  child: Text(club.name),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: "Club",
                border: const OutlineInputBorder(),
                errorText: _formSubmitted && _selectedClub == null
                    ? "Field is required"
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                errorText: _formSubmitted && _passwordController.text.isEmpty
                    ? "Field is required"
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordConfirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                errorText:
                    _formSubmitted && _passwordConfirmController.text.isEmpty
                        ? "Field is required"
                        : null,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _formSubmitted = true;
                });

                if (_passwordController.text ==
                    _passwordConfirmController.text) {
                  _registerUser();
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Password Mismatch"),
                      content:
                          const Text("Please make sure both passwords match."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
