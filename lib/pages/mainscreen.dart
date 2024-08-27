import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imagecloud/pages/storage.dart';
import 'package:imagecloud/pages/folder.dart';
import 'package:imagecloud/pages/login.dart'; // Ensure you import the Login page

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final List<Widget> _pages = [
    const Storage(), // Storage Page
    const Folder(), // Folder Page
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      // If Logout is tapped
      await _logout();
    } else {
      setState(() {
        _currentIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  Future<void> _logout() async {
    // Clear the token from secure storage
    await _secureStorage.delete(key: 'access_token');

    // Navigate to the login screen and remove the current stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          if (_currentIndex == 0) {
            // If on the first page, allow the app to close
            return true;
          } else {
            // Navigate to the first page instead of exiting
            _onItemTapped(0);
            return false;
          }
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _pages,
        ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
