import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'decouvrir/decouvrir_screen.dart';
import 'annonce/creer_annonce_screen.dart';
import 'messages/conversations_screen.dart';
import 'profil/profil_screen.dart';
import 'admin/admin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _estSuperAdmin = false;
  bool _chargementRole = true;

  // Dimensions de la nav — le bouton "+" dépasse au-dessus de la barre
  static const double _barHeight = 62;
  static const double _boutonTaille = 60;
  static const double _depassement = (_boutonTaille / 3) - 5;
  static const double _hauteurTotale = _barHeight + _depassement;

  // Favoris retiré de la nav — accessible depuis Profil > Mes favoris
  final List<Widget> _pages = const [
    HomeScreen(),
    DecouvrirScreen(),
    ConversationsScreen(),
    ProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _verifierRole();
  }

  Future<void> _verifierRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _chargementRole = false);
      return;
    }
    final data = await Supabase.instance.client
        .from('profils')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    if (mounted) {
      setState(() {
        _estSuperAdmin = data?['role'] == 'superadmin';
        _chargementRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargementRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Si SuperAdmin → interface dédiée
    if (_estSuperAdmin) {
      return const AdminScreen();
    }

    // Interface utilisateur normale
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _pages[_currentIndex],
          _buildFloatingNav(),
        ],
      ),
    );
  }

  // ── Bottom nav flottante — pilule navy + bouton "+" surélevé ──
  Widget _buildFloatingNav() {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: SizedBox(
        height: _hauteurTotale,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Barre
            Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: AppShadows.nav,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavIcon(Icons.home_outlined, 0),
                  _buildNavIcon(Icons.search, 1),
                  const SizedBox(width: _boutonTaille), // espace réservé au bouton
                  _buildNavIcon(Icons.chat_bubble_outline, 2),
                  _buildNavIcon(Icons.person_outline, 3),
                ],
              ),
            ),
            // Bouton "+" — dépasse au-dessus de la barre
            const Positioned(
              top: 0,
              child: _CenterButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: active ? AppColors.primary : Colors.white.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreerAnnonceScreen()),
        );
      },
      child: Container(
        width: _MainScreenState._boutonTaille,
        height: _MainScreenState._boutonTaille,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}