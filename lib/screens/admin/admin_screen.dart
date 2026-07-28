import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import 'categories_screen.dart';
import 'admin_profil_screen.dart';
import '../../widgets/confirmation_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _service = AdminService();
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    _DashboardTab(service: _service),
    _UtilisateursTab(service: _service),
    _AnnoncesTab(service: _service),
    _SignalementsTab(service: _service),
    AdminProfilScreen(
      service: _service,
      onVoirSignalements: () => setState(() => _currentIndex = 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _pages[_currentIndex],
          _buildBottomNav(),
          if (_currentIndex == 0)
            Positioned(
              bottom: 92,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child:
                  const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.grid_view_rounded, label: 'Dashboard'),
      (icon: Icons.group_outlined, label: 'Users'),
      (icon: Icons.gavel_outlined, label: 'Annonces'),
      (icon: Icons.flag_outlined, label: 'Signal.'),
      (icon: Icons.person_outline, label: 'Profil'),
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.navy.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final actif = _currentIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: actif
                    ? BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                  BorderRadius.circular(AppRadius.full),
                )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].icon, color: Colors.white, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                        actif ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  final AdminService service;
  const _DashboardTab({required this.service});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _stats;
  List<int> _inscriptions = [];
  List<Map<String, dynamic>> _activite = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final stats = await widget.service.getStatistiquesAvancees();
    final inscriptions = await widget.service.getInscriptions30Jours();
    final activite = await widget.service.getActiviteRecente();
    setState(() {
      _stats = stats;
      _inscriptions = inscriptions;
      _activite = activite;
      _loading = false;
    });
  }

  String _tempsEcoule(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final stats = _stats!;
    final croissanceUsers = stats['croissanceUtilisateurs'] as double?;
    final croissanceAnnonces = stats['croissanceAnnonces'] as double?;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord', style: AppTextStyles.displayMd),
            const SizedBox(height: 4),
            Text(
              "Résumé de l'activité du réseau Rizen aujourd'hui.",
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.rosyTaupe,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            if ((stats['litiges'] as int? ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.stackLg),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border(
                    left: BorderSide(color: AppColors.error, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_outlined,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${stats['litiges']} litige(s) en attente',
                        style: AppTextStyles.titleMd.copyWith(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'UTILISATEURS',
                    '${stats['utilisateurs']}',
                    croissanceUsers,
                    Icons.people_outline,
                    const Color(0xFFE0E7FF),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: _buildStatCard(
                    'ANNONCES ACTIVES',
                    '${stats['annoncesActives']}',
                    croissanceAnnonces,
                    Icons.local_offer_outlined,
                    const Color(0xFFFFEDD5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'TRANSACTIONS (MOIS)',
                    '${stats['transactionsMois']}',
                    null,
                    Icons.swap_horiz,
                    const Color(0xFFF3F4F6),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: _buildStatCard(
                    'VOLUME TOTAL',
                    '${(stats['volumeTotal'] as double).toStringAsFixed(0)} FCFA',
                    null,
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.stackLg + 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inscriptions — 30 derniers jours',
                      style: AppTextStyles.titleMd.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    'Nouveaux comptes créés par jour',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _AreaChartPainter(
                        _agregerParPaquets(_inscriptions, 10),
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.stackLg + 8),

            _buildComparaisonCharts(stats),

            const SizedBox(height: AppSpacing.stackLg + 8),

            Text('Activité récente', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.stackMd),
            if (_activite.isEmpty)
              Text('Aucune activité récente',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.rosyTaupe))
            else
              ..._activite.map((item) => _buildActiviteItem(item)),
          ],
        ),
      ),
    );
  }

  List<double> _agregerParPaquets(List<int> valeurs, int nbPaquets) {
    if (valeurs.isEmpty) return List.filled(nbPaquets, 0);
    final tailleP = (valeurs.length / nbPaquets).ceil();
    final List<double> resultat = [];
    for (var i = 0; i < valeurs.length; i += tailleP) {
      final fin =
      (i + tailleP < valeurs.length) ? i + tailleP : valeurs.length;
      final paquet = valeurs.sublist(i, fin);
      resultat.add(paquet.reduce((a, b) => a + b) / paquet.length);
    }
    return resultat;
  }

  Widget _buildStatCard(String label, String valeur, double? croissance,
      IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.navy, size: 20),
              ),
              if (croissance != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (croissance >= 0
                        ? AppColors.emerald
                        : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${croissance >= 0 ? '+' : ''}${croissance.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: croissance >= 0
                          ? AppColors.emerald
                          : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.labelCaps),
          Text(
            valeur,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiviteItem(Map<String, dynamic> item) {
    final type = item['type'] as String;
    late IconData icon;
    late Color bg;
    late Color couleur;
    switch (type) {
      case 'signalement':
        icon = Icons.gavel;
        bg = const Color(0xFFFFE4E1);
        couleur = AppColors.error;
        break;
      case 'utilisateur':
        icon = Icons.person_add_outlined;
        bg = const Color(0xFFE0E7FF);
        couleur = Colors.indigo;
        break;
      default:
        icon = Icons.shopping_cart_outlined;
        bg = const Color(0xFFD1FAE5);
        couleur = AppColors.emerald;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: couleur, size: 20),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['titre'] as String,
                    style: AppTextStyles.titleMd.copyWith(fontSize: 15)),
                Text(
                  item['sousTitre'] as String,
                  style: AppTextStyles.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _tempsEcoule(item['date'] as DateTime),
            style: AppTextStyles.bodySm.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildComparaisonCharts(Map<String, dynamic> stats) {
    final valeurs = {
      'Utilisateurs': (stats['utilisateurs'] as int).toDouble(),
      'Annonces actives': (stats['annoncesActives'] as int).toDouble(),
      'Transactions (mois)': (stats['transactionsMois'] as int).toDouble(),
    };
    final couleurs = [Colors.indigo, AppColors.primary, AppColors.emerald];
    final maxY = valeurs.values.reduce((a, b) => a > b ? a : b) * 1.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition globale', style: AppTextStyles.titleMd),
          const SizedBox(height: AppSpacing.stackMd),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY <= 0 ? 1 : maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: AppTextStyles.bodySm.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Users', 'Annonces', 'Trans.'];
                        if (value.toInt() >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[value.toInt()],
                              style: AppTextStyles.bodySm
                                  .copyWith(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.paleOak, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(valeurs.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: valeurs.values.elementAt(i),
                        color: couleurs[i],
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> valeurs;
  final Color couleur;

  _AreaChartPainter(this.valeurs, this.couleur);

  @override
  void paint(Canvas canvas, Size size) {
    if (valeurs.isEmpty) return;

    final maxVal = valeurs.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1.0 : maxVal;

    final dashPaint = Paint()
      ..color = AppColors.paleOak.withOpacity(0.5)
      ..strokeWidth = 1;
    for (double y = 0; y <= size.height; y += size.height / 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dashPaint);
    }

    final stepX = size.width / (valeurs.length - 1).clamp(1, 999);
    final points = <Offset>[];
    for (var i = 0; i < valeurs.length; i++) {
      final x = i * stepX;
      final y = size.height - (valeurs[i] / maxY) * size.height;
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    final linePaint = Paint()
      ..color = couleur
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [couleur.withOpacity(0.3), couleur.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      oldDelegate.valeurs != valeurs;
}

// ─────────────────────────────────────────────
// Signalements — Reports
// ─────────────────────────────────────────────
class _SignalementsTab extends StatefulWidget {
  final AdminService service;
  const _SignalementsTab({required this.service});

  @override
  State<_SignalementsTab> createState() => _SignalementsTabState();
}

enum _FiltreTraitement { tous, nonTraites, traites }

class _SignalementsTabState extends State<_SignalementsTab> {
  List<Map<String, dynamic>> _signalements = [];
  List<Map<String, dynamic>> _litiges = [];
  bool _loading = true;
  bool _vueLitiges = false;
  _FiltreTraitement _filtre = _FiltreTraitement.tous;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final signalements = await widget.service.getSignalements();
    final litiges = await widget.service.getLitiges();
    setState(() {
      _signalements = signalements;
      _litiges = litiges;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _signalementsFiltres {
    switch (_filtre) {
      case _FiltreTraitement.nonTraites:
        return _signalements
            .where((s) => (s['statut'] ?? 'en_attente') == 'en_attente')
            .toList();
      case _FiltreTraitement.traites:
        return _signalements
            .where((s) => (s['statut'] ?? 'en_attente') != 'en_attente')
            .toList();
      case _FiltreTraitement.tous:
        return _signalements;
    }
  }

  List<Map<String, dynamic>> get _litigesFiltres {
    switch (_filtre) {
      case _FiltreTraitement.nonTraites:
        return _litiges.where((l) => l['statut'] == 'litige').toList();
      case _FiltreTraitement.traites:
        return _litiges.where((l) => l['statut'] != 'litige').toList();
      case _FiltreTraitement.tous:
        return _litiges;
    }
  }

  String _tempsEcoule(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final enAttente =
        _signalements.where((s) => (s['statut'] ?? 'en_attente') == 'en_attente').length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signalements', style: AppTextStyles.displayMd),
            const SizedBox(height: 8),
            Text(
              "Gérez les alertes et maintenez l'intégrité de la plateforme.",
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.rosyTaupe,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg + 8),

            // Sélecteur Signalements / Litiges
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSelecteurItem(
                      label: 'Signalements',
                      badge: _signalements
                          .where((s) =>
                      (s['statut'] ?? 'en_attente') == 'en_attente')
                          .length,
                      actif: !_vueLitiges,
                      onTap: () => setState(() {
                        _vueLitiges = false;
                        _filtre = _FiltreTraitement.tous;
                      }),
                    ),
                  ),
                  Expanded(
                    child: _buildSelecteurItem(
                      label: 'Litiges',
                      badge: _litiges
                          .where((l) => l['statut'] == 'litige')
                          .length,
                      actif: _vueLitiges,
                      onTap: () => setState(() {
                        _vueLitiges = true;
                        _filtre = _FiltreTraitement.tous;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),

            // Filtre Traité / Non traité
            Row(
              children: _FiltreTraitement.values.map((f) {
                final label = switch (f) {
                  _FiltreTraitement.tous => 'Tous',
                  _FiltreTraitement.nonTraites => 'Non traités',
                  _FiltreTraitement.traites => 'Traités',
                };
                final selected = _filtre == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtre = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.navy
                            : AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(AppRadius.full),
                        boxShadow: selected ? null : AppShadows.card,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                          selected ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.stackLg + 8),

            if (_vueLitiges) ...[
              if (_litigesFiltres.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.balance_outlined,
                            size: 56, color: AppColors.paleOak),
                        const SizedBox(height: 12),
                        Text('Aucun litige dans cette catégorie',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.rosyTaupe)),
                      ],
                    ),
                  ),
                )
              else
                ..._litigesFiltres.map((l) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: AppSpacing.stackMd),
                  child: _buildLitigeCard(l),
                )),
            ] else ...[
              if (_signalementsFiltres.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 56, color: AppColors.paleOak),
                        const SizedBox(height: 12),
                        Text('Aucun signalement dans cette catégorie',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.rosyTaupe)),
                      ],
                    ),
                  ),
                )
              else
                ..._signalementsFiltres.map((s) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: AppSpacing.stackMd),
                  child: _buildReportCard(s),
                )),
            ],

            const SizedBox(height: AppSpacing.stackLg),
            _buildBanniereInfo(enAttente),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> s) {
    final annonce = s['annonces'] as Map<String, dynamic>?;
    final statut = s['statut'] as String? ?? 'en_attente';
    final estTraite = statut != 'en_attente';
    final raison = (s['raison'] as String?) ?? 'Signalement';

    late Color statusBg;
    late Color statusText;
    late String statusLabel;
    switch (statut) {
      case 'traite':
        statusBg = AppColors.emerald.withOpacity(0.12);
        statusText = AppColors.emerald;
        statusLabel = 'Traité';
        break;
      case 'rejete':
        statusBg = AppColors.paleOak.withOpacity(0.4);
        statusText = AppColors.rosyTaupe;
        statusLabel = 'Rejeté';
        break;
      default:
        statusBg = const Color(0xFFE0E7FF);
        statusText = const Color(0xFF4361EE);
        statusLabel = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raison,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${_tempsEcoule(s['created_at'] as String?)} • ID #${s['id']}',
                      style: AppTextStyles.bodySm.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: statusText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if ((s['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              s['description'] as String,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.navy),
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softBlush,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: AppColors.rosyTaupe, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANNONCE ASSOCIÉE', style: AppTextStyles.labelCaps),
                      Text(
                        annonce?['titre'] ?? 'Annonce supprimée',
                        style:
                        AppTextStyles.titleMd.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              Expanded(
                child: _buildReportButton(
                  label: 'Ignorer',
                  bg: AppColors.softBlush,
                  texte: AppColors.navy,
                  active: !estTraite,
                  onTap: () async {
                    await widget.service.rejeterSignalement(s['id'] as int);
                    _charger();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton(
                  label: 'Sanctionner',
                  bg: AppColors.primary,
                  texte: Colors.white,
                  active: !estTraite && annonce != null,
                  onTap: () async {
                    await widget.service.validerSignalement(
                      s['id'] as int,
                      s['annonce_id'] as int,
                    );
                    _charger();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton({
    required String label,
    required Color bg,
    required Color texte,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: active ? bg : bg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: active ? texte : texte.withOpacity(0.4),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelecteurItem({
    required String label,
    required int badge,
    required bool actif,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: actif ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                color: actif ? Colors.white : AppColors.navy,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: actif
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: actif ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLitigeCard(Map<String, dynamic> litige) {
    final annonce = litige['annonces'] as Map<String, dynamic>?;
    final acheteur = litige['acheteur'] as Map<String, dynamic>?;
    final vendeur = litige['vendeur'] as Map<String, dynamic>?;
    final images = (annonce?['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl =
    images.isNotEmpty ? images.first['url_image'] as String : null;
    final prix = (litige['prix_final'] as num).toDouble();
    final motif = litige['motif_litige'] as String?;
    final statut = litige['statut'] as String;
    final estTraite = statut != 'litige';

    late String badgeLabel;
    late Color badgeColor;
    if (!estTraite) {
      badgeLabel = 'Action requise';
      badgeColor = AppColors.error;
    } else if (statut == 'remboursee') {
      badgeLabel = 'Remboursé';
      badgeColor = AppColors.error;
    } else {
      badgeLabel = 'Fonds libérés';
      badgeColor = AppColors.emerald;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Litige — Transaction #${litige['id']}',
                  style: AppTextStyles.titleMd.copyWith(fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 64,
                  height: 64,
                  color: AppColors.softBlush,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.paleOak),
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce?['titre'] ?? 'Annonce supprimée',
                      style: AppTextStyles.titleMd.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${prix.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          const Divider(color: AppColors.paleOak, height: 1),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACHETEUR', style: AppTextStyles.labelCaps),
                  Text(
                    '${acheteur?['prenom'] ?? ''} ${acheteur?['nom'] ?? ''}',
                    style: AppTextStyles.titleMd.copyWith(fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('VENDEUR', style: AppTextStyles.labelCaps),
                  Text(
                    '${vendeur?['prenom'] ?? ''} ${vendeur?['nom'] ?? ''}',
                    style: AppTextStyles.titleMd.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softBlush,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Motif du litige',
                          style: AppTextStyles.titleMd.copyWith(
                              fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        (motif == null || motif.isEmpty)
                            ? 'Aucun motif renseigné'
                            : motif,
                        style: AppTextStyles.bodySm.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              Expanded(
                child: _buildLitigeButton(
                  label: 'Rembourser',
                  couleur: AppColors.error,
                  icon: Icons.undo_rounded,
                  active: !estTraite,
                  onTap: () => _resoudreLitige(litige, favorVendeur: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLitigeButton(
                  label: 'Libérer les fonds',
                  couleur: AppColors.emerald,
                  icon: Icons.account_balance_wallet_outlined,
                  active: !estTraite,
                  onTap: () => _resoudreLitige(litige, favorVendeur: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLitigeButton({
    required String label,
    required Color couleur,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: active ? couleur : couleur.withOpacity(0.35),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resoudreLitige(Map<String, dynamic> litige,
      {required bool favorVendeur}) async {
    final confirm = await confirmerAction(
      context,
      titre: favorVendeur ? 'Libérer les fonds ?' : 'Rembourser l\'acheteur ?',
      message: favorVendeur
          ? 'Les fonds seront versés au vendeur et la transaction marquée terminée.'
          : "L'acheteur sera remboursé et l'annonce repassera active.",
      labelConfirmer: 'Confirmer',
      couleurConfirmer:
      favorVendeur ? AppColors.emerald : AppColors.error,
    );

    if (confirm == true) {
      try {
        await widget.service.resoldreLitige(
          litige['id'] as int,
          litige['annonce_id'] as int,
          favorVendeur,
        );
        _charger();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(favorVendeur
                ? 'Fonds libérés au vendeur'
                : 'Acheteur remboursé')),
          );
        }
      } catch (e) {
        debugPrint('Erreur resoldreLitige: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }

  Widget _buildBanniereInfo(int enAttente) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            enAttente > 0 ? Icons.warning_amber_rounded : Icons.shield_outlined,
            color: AppColors.primary,
            size: 26,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            enAttente > 0
                ? '$enAttente signalement${enAttente > 1 ? 's' : ''} en attente'
                : 'Aucun signalement en attente',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            enAttente > 0
                ? 'Ces signalements attendent une décision (ignorer ou sanctionner).'
                : 'Le catalogue est à jour, rien à traiter pour le moment.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Annonces — Modération
// ─────────────────────────────────────────────
enum _FiltreAnnonce { toutes, signalees, actives }

class _AnnoncesTab extends StatefulWidget {
  final AdminService service;
  const _AnnoncesTab({required this.service});

  @override
  State<_AnnoncesTab> createState() => _AnnoncesTabState();
}

class _AnnoncesTabState extends State<_AnnoncesTab> {
  List<Map<String, dynamic>> _annonces = [];
  Map<String, dynamic>? _apercu;
  bool _loading = true;
  _FiltreAnnonce _filtre = _FiltreAnnonce.toutes;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final annonces = await widget.service.getAnnoncesAvecSignalements();
    final apercu = await widget.service.getApercuModeration();
    setState(() {
      _annonces = annonces;
      _apercu = apercu;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _annoncesFiltrees {
    switch (_filtre) {
      case _FiltreAnnonce.toutes:
        return _annonces;
      case _FiltreAnnonce.signalees:
        return _annonces
            .where((a) => (a['nombreSignalements'] as int) > 0)
            .toList();
      case _FiltreAnnonce.actives:
        return _annonces
            .where((a) =>
        a['statut'] == 'active' &&
            (a['nombreSignalements'] as int) == 0)
            .toList();
    }
  }

  Future<void> _supprimer(Map<String, dynamic> annonce) async {
    final confirm = await confirmerAction(
      context,
      titre: 'Confirmer la suppression',
      message:
      'Supprimer définitivement "${annonce['titre']}" ? Cette action est irréversible.',
      labelConfirmer: 'Supprimer',
      destructif: true,
    );
    if (confirm == true) {
      await widget.service.supprimerAnnonce(annonce['id'] as int);
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final liste = _annoncesFiltrees;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modération', style: AppTextStyles.displayMd),
            const SizedBox(height: 8),
            Text(
              "Gérez l'intégrité du catalogue et les signalements.",
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.rosyTaupe,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            Row(
              children: _FiltreAnnonce.values.map((f) {
                final label = switch (f) {
                  _FiltreAnnonce.toutes => 'Toutes',
                  _FiltreAnnonce.signalees => 'Signalées',
                  _FiltreAnnonce.actives => 'Actives',
                };
                final selected = _filtre == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtre = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(AppRadius.full),
                        boxShadow: selected ? null : AppShadows.card,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                          selected ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.stackLg + 8),

            if (liste.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('Aucune annonce dans cette catégorie',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.rosyTaupe)),
                ),
              )
            else
              ...liste.map((a) => Padding(
                padding:
                const EdgeInsets.only(bottom: AppSpacing.stackLg),
                child: _buildAdCard(a),
              )),

            _buildApercuCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> annonce) {
    final profil = annonce['profils'] as Map<String, dynamic>?;
    final images = (annonce['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl =
    images.isNotEmpty ? images.first['url_image'] as String : null;
    final statut = annonce['statut'] as String;
    final nombreSignalements = annonce['nombreSignalements'] as int;
    final estSignalee = nombreSignalements > 0;

    late String badgeLabel;
    late Color badgeColor;
    if (estSignalee) {
      badgeLabel = 'Signalé';
      badgeColor = AppColors.error;
    } else if (statut == 'suspendue') {
      badgeLabel = 'Masquée';
      badgeColor = Colors.orange;
    } else if (statut == 'vendue') {
      badgeLabel = 'Vendue';
      badgeColor = Colors.blue;
    } else {
      badgeLabel = 'Active';
      badgeColor = AppColors.emerald;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 160,
                  width: double.infinity,
                  color: AppColors.softBlush,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.paleOak, size: 40),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        annonce['titre'] ?? '',
                        style:
                        AppTextStyles.titleMd.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(annonce['prix_actuel'] as num).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 15, color: AppColors.rosyTaupe),
                    const SizedBox(width: 4),
                    Text(
                      'Vendeur : ${profil?['prenom'] ?? ''} ${profil?['nom'] ?? ''}',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: estSignalee
                        ? AppColors.error.withOpacity(0.08)
                        : AppColors.emerald.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        estSignalee
                            ? Icons.flag_outlined
                            : Icons.check_circle_outline,
                        size: 14,
                        color: estSignalee
                            ? AppColors.error
                            : AppColors.emerald,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        estSignalee
                            ? '$nombreSignalements signalement${nombreSignalements > 1 ? 's' : ''}'
                            : 'Aucun signalement',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: estSignalee
                              ? AppColors.error
                              : AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: statut == 'suspendue'
                            ? 'Réactiver'
                            : 'Masquer',
                        couleur: statut == 'suspendue'
                            ? AppColors.emerald
                            : AppColors.navy,
                        rempli: true,
                        onTap: () async {
                          if (statut == 'suspendue') {
                            await widget.service
                                .reactiverAnnonce(annonce['id'] as int);
                          } else {
                            await widget.service
                                .masquerAnnonce(annonce['id'] as int);
                          }
                          _charger();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Supprimer',
                        couleur: AppColors.error,
                        rempli: false,
                        onTap: () => _supprimer(annonce),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color couleur,
    required bool rempli,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: rempli ? couleur : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: rempli ? null : Border.all(color: couleur, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: rempli ? Colors.white : couleur,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApercuCard() {
    final apercu = _apercu;
    if (apercu == null) return const SizedBox.shrink();
    final tauxTraites = apercu['tauxTraites'] as double?;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.analytics_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          const Text(
            'Aperçu Modération',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${apercu['enAttente']} signalement(s) non encore traité(s).',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          _buildSummaryRow(
            'Signalements traités',
            tauxTraites != null
                ? '${tauxTraites.toStringAsFixed(0)}%'
                : '—',
            AppColors.emerald,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _buildSummaryRow(
            'Annonces masquées',
            '${apercu['annoncesMasquees']}',
            Colors.white.withOpacity(0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String valeur, Color couleurValeur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            valeur,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: couleurValeur,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Utilisateurs
// ─────────────────────────────────────────────
enum _FiltreUtilisateur { tous, actifs, suspendus }

class _UtilisateursTab extends StatefulWidget {
  final AdminService service;
  const _UtilisateursTab({required this.service});

  @override
  State<_UtilisateursTab> createState() => _UtilisateursTabState();
}

class _UtilisateursTabState extends State<_UtilisateursTab> {
  List<Map<String, dynamic>> _utilisateurs = [];
  bool _loading = true;
  String _recherche = '';
  _FiltreUtilisateur _filtre = _FiltreUtilisateur.tous;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await widget.service.getUtilisateurs();
    setState(() {
      _utilisateurs = data;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _utilisateursFiltres {
    var liste = _utilisateurs;

    switch (_filtre) {
      case _FiltreUtilisateur.actifs:
        liste = liste.where((u) => (u['statut'] ?? 'actif') != 'suspendu').toList();
        break;
      case _FiltreUtilisateur.suspendus:
        liste = liste.where((u) => u['statut'] == 'suspendu').toList();
        break;
      case _FiltreUtilisateur.tous:
        break;
    }

    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      liste = liste.where((u) {
        final nom = '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return nom.contains(q) || email.contains(q);
      }).toList();
    }

    return liste;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    const mois = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmerSuppression(Map<String, dynamic> user) async {
    final confirm = await confirmerAction(
      context,
      titre: 'Confirmer la suppression',
      message:
      'Supprimer définitivement ${user['prenom']} ${user['nom']} ? Cette action est irréversible.',
      labelConfirmer: 'Supprimer',
      destructif: true,
    );
    if (confirm == true) {
      await widget.service.supprimerUtilisateur(user['id'] as String);
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final liste = _utilisateursFiltres;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Utilisateurs', style: AppTextStyles.displayMd),
            const SizedBox(height: AppSpacing.stackLg),

            // Recherche
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _recherche = v),
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.rosyTaupe, size: 20),
                  hintText: 'Rechercher un utilisateur...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.rosyTaupe,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // Filtres
            Row(
              children: _FiltreUtilisateur.values.map((f) {
                final label = switch (f) {
                  _FiltreUtilisateur.tous => 'Tous',
                  _FiltreUtilisateur.actifs => 'Actifs',
                  _FiltreUtilisateur.suspendus => 'Suspendus',
                };
                final selected = _filtre == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtre = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(AppRadius.full),
                        boxShadow: selected ? null : AppShadows.card,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                          selected ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.stackLg + 8),

            if (liste.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('Aucun utilisateur trouvé',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.rosyTaupe)),
                ),
              )
            else
              ...liste.map((u) => Padding(
                padding:
                const EdgeInsets.only(bottom: AppSpacing.stackMd),
                child: _buildUserCard(u),
              )),

            // Placeholder ajout manuel (pas encore de flux de création
            // de compte côté admin — Supabase Auth nécessiterait un
            // vrai flux d'inscription, pas juste un insert en base)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.softBlush,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_add_outlined,
                      color: AppColors.rosyTaupe, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    'Ajouter manuellement un utilisateur',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.rosyTaupe,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final statut = user['statut'] as String? ?? 'actif';
    final estSuspendu = statut == 'suspendu';
    final photo = user['photo'] as String?;
    final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.softBlush,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? const Icon(Icons.person_outline,
                    color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom.isEmpty ? 'Utilisateur' : nom,
                        style:
                        AppTextStyles.titleMd.copyWith(fontSize: 16)),
                    Text(user['email'] ?? '', style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _confirmerSuppression(user),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Icon(Icons.delete_outline,
                      color: AppColors.paleOak, size: 18),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (estSuspendu ? AppColors.error : AppColors.emerald)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  estSuspendu ? 'Suspendu' : 'Actif',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: estSuspendu ? AppColors.error : AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          const Divider(color: AppColors.paleOak, height: 1),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INSCRIPTION', style: AppTextStyles.labelCaps),
                  Text(
                    _formatDate(user['created_at'] as String?),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  if (estSuspendu) {
                    await widget.service
                        .reactiverUtilisateur(user['id'] as String);
                  } else {
                    await widget.service
                        .suspendreUtilisateur(user['id'] as String);
                  }
                  _charger();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    color: estSuspendu
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: estSuspendu
                        ? null
                        : Border.all(color: AppColors.navy, width: 1.5),
                  ),
                  child: Text(
                    estSuspendu ? 'Réactiver' : 'Suspendre',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: estSuspendu ? Colors.white : AppColors.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}