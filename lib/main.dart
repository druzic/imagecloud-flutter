import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:imagecloud/pages/home.dart';
import 'package:imagecloud/pages/login.dart';
import 'package:imagecloud/pages/register.dart';
import 'package:imagecloud/pages/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');

  String initialRoute;
  if (token != null) {
    // Provjera je li token valjan
    final bool isTokenValid = !JwtDecoder.isExpired(token);
    print(isTokenValid);
    initialRoute = isTokenValid ? '/storage' : '/';
  } else {
    initialRoute = '/';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const Home(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/storage': (context) => const Storage(),
      },
    );
  }
}
