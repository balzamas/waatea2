import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waatea2_client/models/user_model.dart';
import 'package:waatea2_client/screens/signup.dart';

import '../globals.dart' as globals;
import '../models/currentseason_model.dart';
import '../models/password_reset_request.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  late String _token = '';

  bool _loginLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadCredentialsAndLogin() {
    _loadCredentials().then((_) {
      if (_token.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          _loginProcess(
            _token,
            _usernameController.text.toLowerCase(),
          );
        });
      }
    });
  }

  Future<void> _loadCredentials() async {
    final sharedPreferences =
        await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _usernameController.text =
          sharedPreferences.getString('email') ?? '';

      _token =
          sharedPreferences.getString('token') ?? '';
    });
  }

  Future<void> _loginProcess(
    String token,
    String username,
  ) async {
    final http.Response response2 = await http.get(
      Uri.parse(
        '${globals.URL_PREFIX}'
        '/api/users/filter?email=$username',
      ),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response2.statusCode != 200) {
      return;
    }

    final responseJson = json.decode(response2.body);

    if (responseJson is! List ||
        responseJson.isEmpty) {
      return;
    }

    String clubid =
        responseJson[0]['club']['pk'];

    int userid =
        responseJson[0]['pk'];

    String responseBody =
        utf8.decode(response2.bodyBytes);

    final itemsUser =
        json
            .decode(responseBody)
            .cast<Map<String, dynamic>>();

    List<UserModel> users =
        itemsUser.map<UserModel>((json) {
      return UserModel.fromJson(json);
    }).toList();

    final responseCurrentseason =
        await http.get(
      Uri.parse(
        '${globals.URL_PREFIX}'
        '/api/currentseason/filter'
        '?club=$clubid',
      ),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    final itemsCurrentseason =
        json
            .decode(responseCurrentseason.body)
            .cast<Map<String, dynamic>>();

    List<CurrentSeasonModel> currentseason =
        itemsCurrentseason
            .map<CurrentSeasonModel>((json) {
      return CurrentSeasonModel.fromJson(json);
    }).toList();

    String season =
        currentseason[0].season;

    globals.playerId = userid;
    globals.clubId = clubid;
    globals.seasonID = season;
    globals.token = token;
    globals.player = users[0];

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyHomePage(initialIndex: 1),
      ),
    );
  }

  Future<void> _login() async {
    if (_loginLoading) {
      return;
    }

    String username =
        _usernameController.text.trim();

    String password =
        _passwordController.text.trim();

    if (username.isEmpty ||
        password.isEmpty) {
      _showError(
        'Please enter your email and password.',
      );
      return;
    }

    setState(() {
      _loginLoading = true;
    });

    final String apiUrl =
        '${globals.URL_PREFIX}/api-token-auth/';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    final Map<String, String> body = {
      'username': username,
      'password': password,
    };

    try {
      final http.Response response =
          await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final sharedPreferences =
            await SharedPreferences.getInstance();

        await sharedPreferences.setString(
          'email',
          _usernameController.text.trim(),
        );

        //
        // Remove a password stored by older versions
        // of the app.
        //
        await sharedPreferences.remove(
          'password',
        );

        String token =
            json.decode(response.body)['token'];

        await sharedPreferences.setString(
          'token',
          token,
        );

        await _loginProcess(
          token,
          username.toLowerCase(),
        );
      } else {
        if (!mounted) {
          return;
        }

        _showError(
          'Failed to log in. Please check '
          'your email and password.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Could not connect to the server. '
        'Please try again.',
      );

      debugPrint(
        'Login error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loginLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog()
      async {
    final emailController =
        TextEditingController(
      text: _usernameController.text.trim(),
    );

    bool sending = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> submit() async {
              if (sending) {
                return;
              }

              final email =
                  emailController.text.trim();

              if (!_looksLikeEmail(email)) {
                setDialogState(() {
                  errorMessage =
                      'Please enter a valid email address.';
                });
                return;
              }

              setDialogState(() {
                sending = true;
                errorMessage = null;
              });

              final request =
                  PasswordResetRequest(
                email: email,
              );

              try {
                final response =
                    await http.post(
                  Uri.parse(
                    '${globals.URL_PREFIX}'
                    '/api/password-reset/',
                  ),
                  headers: {
                    'Content-Type':
                        'application/json',
                  },
                  body: json.encode(
                    request.toJson(),
                  ),
                );

                if (!dialogContext.mounted) {
                  return;
                }

                if (response.statusCode ==
                    200) {
                  Navigator.of(
                    dialogContext,
                  ).pop();

                  if (!mounted) {
                    return;
                  }

                  await _showPasswordResetSuccess();
                  return;
                }

                String message =
                    'Could not request a password '
                    'reset. Please try again.';

                try {
                  final body =
                      json.decode(response.body);

                  if (body is Map &&
                      body['email'] is List &&
                      body['email'].isNotEmpty) {
                    message =
                        body['email'][0]
                            .toString();
                  } else if (body is Map &&
                      body['detail'] != null) {
                    message =
                        body['detail']
                            .toString();
                  }
                } catch (_) {
                  // Keep the generic message.
                }

                setDialogState(() {
                  sending = false;
                  errorMessage = message;
                });
              } catch (e) {
                if (!dialogContext.mounted) {
                  return;
                }

                debugPrint(
                  'Password reset error: $e',
                );

                setDialogState(() {
                  sending = false;
                  errorMessage =
                      'Could not connect to the '
                      'server. Please try again.';
                });
              }
            }

            return AlertDialog(
              title: const Text(
                'Forgot password?',
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your email address. '
                      'We will send you a link to '
                      'reset your password.',
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller:
                          emailController,
                      enabled: !sending,
                      autofocus: true,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      decoration:
                          InputDecoration(
                        labelText: 'Email',
                        errorText:
                            errorMessage,
                        border:
                            const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) {
                        submit();
                      },
                    ),
                    if (sending) ...[
                      const SizedBox(
                        height: 20,
                      ),
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      sending
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed:
                      sending
                          ? null
                          : submit,
                  child:
                      const Text(
                    'Send reset link',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  bool _looksLikeEmail(String value) {
    final email = value.trim();

    if (email.isEmpty) {
      return false;
    }

    final at = email.indexOf('@');

    return at > 0 &&
        at < email.length - 1 &&
        email.substring(at + 1).contains('.');
  }

  Future<void> _showPasswordResetSuccess()
      async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Check your email',
          ),
          content: const Text(
            'If an account exists for this '
            'email address, a password reset '
            'link has been sent.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey ==
                LogicalKeyboardKey.enter) {
          _login();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: Padding(
          padding:
              const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              TextField(
                controller:
                    _usernameController,
                enabled: !_loginLoading,
                keyboardType:
                    TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.email,
                ],
                decoration:
                    const InputDecoration(
                  labelText:
                      'Username/Email',
                ),
                onSubmitted: (_) =>
                    _login(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller:
                    _passwordController,
                enabled: !_loginLoading,
                decoration:
                    const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                autofillHints: const [
                  AutofillHints.password,
                ],
                onSubmitted: (_) =>
                    _login(),
              ),

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      _loginLoading
                          ? null
                          : _showForgotPasswordDialog,
                  child: const Text(
                    'Forgot password?',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Focus(
                autofocus: true,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black,
                  ),
                  onPressed:
                      _loginLoading
                          ? null
                          : _login,
                  child:
                      _loginLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 55),

              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.black,
                ),
                onPressed:
                    _loginLoading
                        ? null
                        : () {
                            Navigator
                                .pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        SignUpScreen(),
                              ),
                            );
                          },
                child: const Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}