import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:imagecloud/pages/home.dart';
import 'package:imagecloud/pages/login.dart';
import 'package:imagecloud/pages/register.dart';
import 'package:imagecloud/pages/storage.dart';
import 'package:imagecloud/pages/folder.dart'; // Pretpostavimo da postoji folder stranica

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');

  String initialRoute;
  if (token != null) {
    final bool isTokenValid = !JwtDecoder.isExpired(token);
    initialRoute = isTokenValid ? '/main' : '/';
  } else {
    initialRoute = '/';
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
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const Storage(), // Stranica za prikazivanje Storage
    const Folder(), // Stranica za prikazivanje Folder
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Storage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Folder',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
