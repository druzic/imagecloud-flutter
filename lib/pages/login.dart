import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

Future<User> loginUser(
    BuildContext context, String username, String password) async {
  final map = <String, dynamic>{};
  map['username'] = username.toString();
  map['password'] = password.toString();
  final response =
      await http.post(Uri.parse('http://10.0.2.2:8000/login'), body: map);

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    final parsedJson = jsonDecode(response.body);
    final user = User.fromJson(parsedJson);

    // Save token to secure storage
    final storage = FlutterSecureStorage();
    await storage.write(key: 'access_token', value: user.access_token);
    await storage.write(key: 'token_type', value: user.token_type);
    final bool isTokenValid = JwtDecoder.isExpired(user.access_token);
    print('Is token valid: $isTokenValid');
    Navigator.pushReplacementNamed(context, '/storage');
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to create album.');
  }
}

class User {
  final String access_token;
  final String token_type;

  const User({required this.access_token, required this.token_type});

  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'access_token': String access_token,
        'token_type': String token_type,
      } =>
        User(
          access_token: access_token,
          token_type: token_type,
        ),
      _ => throw const FormatException('Failed to load User.'),
    };
  }
}

class _LoginState extends State<Login> {
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  Future<User>? _futureUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Login'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
            child: Column(
          children: [
            TextField(
              controller: _controllerEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: _controllerPassword,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            TextButton(
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () {
                  setState(() {
                    _futureUser = loginUser(context, _controllerEmail.text,
                        _controllerPassword.text);
                  });
                },
                child: const Text("Login"))
          ],
        )),
      ),
    );
  }

  void login() {}
}