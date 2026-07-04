import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'annonce/creer_annonce_screen.dart';
import 'favoris/favoris_screen.dart';
import 'messages/conversations_screen.dart';
import 'profil/profil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    const FavorisScreen(),       // étape 5
    const Center(child: Text('Créer')),
    const ConversationsScreen(),// étape 6
    const ProfilScreen(),        // étape 8
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildCenterButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppColors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.favorite, 1),
            const SizedBox(width: 48), // espace pour le bouton central
            _buildNavItem(Icons.chat_bubble, 3),
            _buildNavItem(Icons.person, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: active ? AppColors.dustyRose : AppColors.rosyTaupe,
              size: 24),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.dustyRose,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreerAnnonceScreen()),
        );
      },
      backgroundColor: AppColors.dustyRose,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}