import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Login'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                icon: const Icon(Icons.app_registration),
                label: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
