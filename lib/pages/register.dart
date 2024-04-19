import 'package:flutter/material.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Register'),
        elevation: 0,
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Register'),
        ),
      ),
    );
  }
}
