import 'package:flutter/material.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/features/home/home_screen.dart';
import 'package:afterlife/features/character_list/character_list_screen.dart';
import 'package:afterlife/features/character_interview/interview_screen.dart';
import 'package:afterlife/features/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CharacterListScreen(),
    const InterviewScreen(editMode: false),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppTheme.backgroundEnd,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Your Twins',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
