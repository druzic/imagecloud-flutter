import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imagecloud/pages/mainscreen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:imagecloud/pages/home.dart';
import 'package:imagecloud/pages/login.dart';
import 'package:imagecloud/pages/register.dart';
import 'package:imagecloud/pages/storage.dart';
import 'package:imagecloud/pages/folder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');

  String initialRoute = '/login';
  if (token != null) {
    final bool isTokenValid = !JwtDecoder.isExpired(token);
    if (isTokenValid) {
      initialRoute = '/main';
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const Home(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/main': (context) => const MainScreen(),
        '/storage': (context) => const Storage(),
        '/folder': (context) => const Folder(),
      },
    );
  }
}
