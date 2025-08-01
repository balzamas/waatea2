import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;
import '../models/club.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

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

  Future<String> getCSRFToken() async {
    final response =
        await http.get(Uri.parse('${globals.URL_PREFIX}/get-csrf-token/'));
    if (response.statusCode == 200) {
      return response.headers['set-cookie'].toString();
    } else {
      throw Exception('Failed to load CSRF token');
    }
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
      "email": _emailController.text.trim().toLowerCase(),
      "password": _passwordController.text,
      "club": _selectedClub!.pk
    };

    final csrfToken = await getCSRFToken();

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json", 'X-CSRFToken': csrfToken},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      // User successfully registered, handle success
      const String apiUrl = "${globals.URL_PREFIX}/api-token-auth/";
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final Map<String, String> body = {
        'username': _emailController.text,
        'password': _passwordController.text
      };

      final http.Response responseLogin = await http.post(Uri.parse(apiUrl),
          headers: headers, body: json.encode(body));

      if (responseLogin.statusCode == 200) {
        // Login successful, extract the token from the response
        String token = json.decode(responseLogin.body)['token'];

        final Map<String, dynamic> body = {
          'mobile_phone': _mobilephoneController.text.trim(),
        };

        final http.Response response = await http.patch(
          Uri.parse(
              '${globals.URL_PREFIX}/api/user-profile/${_emailController.text}/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(body),
        );
      }

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
            SizedBox(height: 24),
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
