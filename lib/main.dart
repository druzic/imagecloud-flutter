import 'package:flutter/material.dart';
import 'package:imagecloud/pages/home.dart';
import 'package:imagecloud/pages/login.dart';
import 'package:imagecloud/pages/register.dart';
import 'package:imagecloud/pages/storage.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const Home(),
      '/login': (context) => const Login(),
      '/register': (context) => const Register(),
      '/storage': (context) => const Storage(),
    },
  ));
}
