import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _service = AdminService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.mauveShadow,
        elevation: 0,
        title: const Text(
          'SuperAdmin',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.dustyRose,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Signalements'),
            Tab(text: 'Annonces'),
            Tab(text: 'Utilisateurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(service: _service),
          _SignalementsTab(service: _service),
          _AnnoncesTab(service: _service),
          _UtilisateursTab(service: _service),
        ],
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
  Map<String, int>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final stats = await widget.service.getStatistiques();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.dustyRose));
    }

    final stats = _stats!;
    return RefreshIndicator(
      color: AppColors.dustyRose,
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerte litiges
            if ((stats['litiges'] ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined,
                        color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${stats['litiges']} litige(s) en attente',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Titre
            Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Cartes stats — 2 colonnes
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Annonces',
                      stats['annonces'] ?? 0,
                      Icons.sell_outlined, Colors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('Utilisateurs',
                      stats['utilisateurs'] ?? 0,
                      Icons.people_outline, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Transactions',
                      stats['transactions'] ?? 0,
                      Icons.receipt_outlined, Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('Signalements',
                      stats['signalements'] ?? 0,
                      Icons.flag_outlined, Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Graphe en barres
            Text(
              'Répartition globale',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.paleOak),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (stats.values.reduce((a, b) => a > b ? a : b) * 1.3)
                      .toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10,
                            color: AppColors.rosyTaupe,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'Annonces',
                            'Users',
                            'Trans.',
                            'Signal.'
                          ];
                          if (value.toInt() >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 10,
                                color: AppColors.rosyTaupe,
                              ),
                            ),
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
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.paleOak,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _buildBarGroup(
                        0, (stats['annonces'] ?? 0).toDouble(), Colors.blue),
                    _buildBarGroup(1,
                        (stats['utilisateurs'] ?? 0).toDouble(), Colors.green),
                    _buildBarGroup(2,
                        (stats['transactions'] ?? 0).toDouble(), Colors.orange),
                    _buildBarGroup(3,
                        (stats['signalements'] ?? 0).toDouble(), Colors.red),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Graphe camembert
            Text(
              'Distribution',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.paleOak),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: (stats['annonces'] ?? 0).toDouble(),
                            color: Colors.blue,
                            radius: 40,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (stats['utilisateurs'] ?? 0).toDouble(),
                            color: Colors.green,
                            radius: 40,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (stats['transactions'] ?? 0).toDouble(),
                            color: Colors.orange,
                            radius: 40,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (stats['signalements'] ?? 0).toDouble(),
                            color: Colors.red,
                            radius: 40,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegende('Annonces', Colors.blue,
                            stats['annonces'] ?? 0),
                        _buildLegende('Utilisateurs', Colors.green,
                            stats['utilisateurs'] ?? 0),
                        _buildLegende('Transactions', Colors.orange,
                            stats['transactions'] ?? 0),
                        _buildLegende('Signalements', Colors.red,
                            stats['signalements'] ?? 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, int valeur, IconData icon, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paleOak),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: couleur, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$valeur',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  color: AppColors.rosyTaupe,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegende(String label, Color couleur, int valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: couleur,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ($valeur)',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Signalements
// ─────────────────────────────────────────────
class _SignalementsTab extends StatefulWidget {
  final AdminService service;
  const _SignalementsTab({required this.service});

  @override
  State<_SignalementsTab> createState() => _SignalementsTabState();
}

class _SignalementsTabState extends State<_SignalementsTab> {
  List<Map<String, dynamic>> _signalements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await widget.service.getSignalements();
    setState(() {
      _signalements = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.dustyRose));
    }

    if (_signalements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 56, color: AppColors.paleOak),
            const SizedBox(height: 12),
            Text('Aucun signalement',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: AppColors.rosyTaupe)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.dustyRose,
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _signalements.length,
        itemBuilder: (context, index) =>
            _buildSignalementItem(_signalements[index]),
      ),
    );
  }

  Widget _buildSignalementItem(Map<String, dynamic> s) {
    final annonce = s['annonces'] as Map<String, dynamic>?;
    final profil = s['profils'] as Map<String, dynamic>?;
    final statut = s['statut'] as String? ?? 'en_attente';
    final estTraite = statut != 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estTraite ? AppColors.paleOak : AppColors.dustyRose,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  annonce?['titre'] ?? 'Annonce supprimée',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _buildStatutBadge(statut),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Signalé par : ${profil?['prenom'] ?? ''} ${profil?['nom'] ?? ''}',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: AppColors.rosyTaupe,
            ),
          ),
          Text(
            'Raison : ${s['raison'] ?? ''}',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: AppColors.rosyTaupe,
            ),
          ),
          if (s['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              s['description'],
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (!estTraite) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await widget.service
                          .rejeterSignalement(s['id'] as int);
                      _charger();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.paleOak),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Rejeter',
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: AppColors.rosyTaupe,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: annonce == null
                        ? null
                        : () async {
                      await widget.service.validerSignalement(
                        s['id'] as int,
                        s['annonce_id'] as int,
                      );
                      _charger();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mauveShadow,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Valider',
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: Colors.white,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color couleur;
    String label;
    switch (statut) {
      case 'traite':
        couleur = Colors.green;
        label = 'Validé';
        break;
      case 'rejete':
        couleur = Colors.grey;
        label = 'Rejeté';
        break;
      default:
        couleur = Colors.orange;
        label = 'En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: couleur)),
    );
  }
}

// ─────────────────────────────────────────────
// Annonces
// ─────────────────────────────────────────────
class _AnnoncesTab extends StatefulWidget {
  final AdminService service;
  const _AnnoncesTab({required this.service});

  @override
  State<_AnnoncesTab> createState() => _AnnoncesTabState();
}

class _AnnoncesTabState extends State<_AnnoncesTab> {
  List<Map<String, dynamic>> _annonces = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await widget.service.getAnnonces();
    setState(() {
      _annonces = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.dustyRose));
    }

    return RefreshIndicator(
      color: AppColors.dustyRose,
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _annonces.length,
        itemBuilder: (context, index) =>
            _buildAnnonceItem(_annonces[index]),
      ),
    );
  }

  Widget _buildAnnonceItem(Map<String, dynamic> annonce) {
    final profil = annonce['profils'] as Map<String, dynamic>?;
    final images = (annonce['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl =
    images.isNotEmpty ? images.first['url_image'] as String : null;
    final statut = annonce['statut'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paleOak),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            )
                : Container(
              width: 60,
              height: 60,
              color: AppColors.softBlush,
              child: Icon(Icons.image_outlined,
                  color: AppColors.paleOak),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annonce['titre'] ?? '',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${profil?['prenom'] ?? ''} ${profil?['nom'] ?? ''}',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    color: AppColors.rosyTaupe,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${(annonce['prix_actuel'] as num).toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mauveShadow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatutAnnonce(statut),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.rosyTaupe),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'masquer') {
                await widget.service.masquerAnnonce(annonce['id'] as int);
                _charger();
              } else if (value == 'supprimer') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Confirmer la suppression'),
                    content:
                    const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await widget.service
                      .supprimerAnnonce(annonce['id'] as int);
                  _charger();
                }
              }
            },
            itemBuilder: (_) => [
              if (statut == 'active')
                const PopupMenuItem(
                  value: 'masquer',
                  child: Row(children: [
                    Icon(Icons.visibility_off_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Masquer'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'supprimer',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatutAnnonce(String statut) {
    Color couleur;
    switch (statut) {
      case 'active':
        couleur = Colors.green;
        break;
      case 'suspendue':
        couleur = Colors.orange;
        break;
      case 'vendue':
        couleur = Colors.blue;
        break;
      default:
        couleur = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Utilisateurs
// ─────────────────────────────────────────────
class _UtilisateursTab extends StatefulWidget {
  final AdminService service;
  const _UtilisateursTab({required this.service});

  @override
  State<_UtilisateursTab> createState() => _UtilisateursTabState();
}

class _UtilisateursTabState extends State<_UtilisateursTab> {
  List<Map<String, dynamic>> _utilisateurs = [];
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.dustyRose));
    }

    return RefreshIndicator(
      color: AppColors.dustyRose,
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _utilisateurs.length,
        itemBuilder: (context, index) =>
            _buildUtilisateurItem(_utilisateurs[index]),
      ),
    );
  }

  Widget _buildUtilisateurItem(Map<String, dynamic> user) {
    final statut = user['statut'] as String? ?? 'actif';
    final estSuspendu = statut == 'suspendu';
    final photo = user['photo'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paleOak),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.softBlush,
            backgroundImage:
            photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Icon(Icons.person_outline, color: AppColors.dustyRose)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: AppColors.rosyTaupe,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: estSuspendu
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estSuspendu ? 'Suspendu' : 'Actif',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: estSuspendu
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.rosyTaupe),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'suspendre') {
                await widget.service
                    .suspendreUtilisateur(user['id'] as String);
                _charger();
              } else if (value == 'reactiver') {
                await widget.service
                    .reactiverUtilisateur(user['id'] as String);
                _charger();
              } else if (value == 'supprimer') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Confirmer la suppression'),
                    content:
                    const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await widget.service
                      .supprimerUtilisateur(user['id'] as String);
                  _charger();
                }
              }
            },
            itemBuilder: (_) => [
              if (!estSuspendu)
                const PopupMenuItem(
                  value: 'suspendre',
                  child: Row(children: [
                    Icon(Icons.block_outlined,
                        size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Suspendre',
                        style: TextStyle(color: Colors.orange)),
                  ]),
                ),
              if (estSuspendu)
                const PopupMenuItem(
                  value: 'reactiver',
                  child: Row(children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Réactiver',
                        style: TextStyle(color: Colors.green)),
                  ]),
                ),
              const PopupMenuItem(
                value: 'supprimer',
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}