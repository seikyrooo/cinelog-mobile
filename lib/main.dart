import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/search_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/community_screen.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const CinelogApp());
}

class CinelogApp extends StatelessWidget {
  const CinelogApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accentRed = Color(0xFFE50914);
    const bgPrimary = Color(0xFF141414);
    const bgSurface = Color(0xFF181818);
    const bgCard = Color(0xFF1F1F1F);

    return MaterialApp(
      title: 'CineLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgPrimary,
        primaryColor: accentRed,
        colorScheme: const ColorScheme.dark(
          primary: accentRed,
          secondary: Color(0xFF46D369),
          surface: bgSurface,
          surfaceContainerHighest: bgCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgPrimary,
          elevation: 0,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    WatchlistScreen(initialMediaType: 'all'),
    CommunityScreen(),
    AuthScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const accentRed = Color(0xFFE50914);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF141414),
          selectedItemColor: accentRed,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
