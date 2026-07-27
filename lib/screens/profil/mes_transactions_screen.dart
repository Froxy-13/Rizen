import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../transaction/paiement_screen.dart';

class MesTransactionsScreen extends StatefulWidget {
  const MesTransactionsScreen({super.key});

  @override
  State<MesTransactionsScreen> createState() => _MesTransactionsScreenState();
}

class _MesTransactionsScreenState extends State<MesTransactionsScreen> {
  final _service = TransactionService();
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  bool _vueVentes = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      if (_userId == null) return;
      final data = await _service.getMesTransactions(_userId);
      setState(() {
        _transactions = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _transactionsFiltrees {
    return _transactions.where((t) {
      final estAcheteur = t['acheteur_id'] == _userId;
      return _vueVentes ? !estAcheteur : estAcheteur;
    }).toList();
  }

  // Groupe les transactions filtrées par mois, la plus récente en premier
  Map<String, List<Map<String, dynamic>>> get _transactionsParMois {
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final Map<String, List<Map<String, dynamic>>> groupes = {};
    for (final t in _transactionsFiltrees) {
      final date = DateTime.tryParse(t['created_at'] ?? '');
      final cle = date != null
          ? '${mois[date.month - 1]} ${date.year}'
          : 'Date inconnue';
      groupes.putIfAbsent(cle, () => []).add(t);
    }
    return groupes;
  }

  double get _totalFiltre {
    return _transactionsFiltrees
        .where((t) => t['statut'] == 'completee')
        .fold<double>(
        0, (sum, t) => sum + (t['prix_final'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final groupes = _transactionsParMois;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _charger,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                    AppSpacing.containerMargin,
                    0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.card,
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.navy, size: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.stackMd),
                      Text('Historique', style: AppTextStyles.displayMd),
                    ],
                  ),
                ),
              ),

              // ── Sélecteur Achats / Ventes ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                    AppSpacing.containerMargin,
                    0,
                  ),
                  child: Container(
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
                            label: 'Achats',
                            actif: !_vueVentes,
                            onTap: () =>
                                setState(() => _vueVentes = false),
                          ),
                        ),
                        Expanded(
                          child: _buildSelecteurItem(
                            label: 'Ventes',
                            actif: _vueVentes,
                            onTap: () => setState(() => _vueVentes = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Carte résumé ──────────────────────────────
              if (!_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin,
                      AppSpacing.stackLg,
                      AppSpacing.containerMargin,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _vueVentes
                                    ? 'TOTAL ENCAISSÉ'
                                    : 'TOTAL DÉPENSÉ',
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_totalFiltre.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _vueVentes
                                  ? Icons.trending_up
                                  : Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Liste groupée par mois ────────────────────
              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                ),
              )
                  : _transactionsFiltrees.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _vueVentes
                            ? Icons.storefront_outlined
                            : Icons.receipt_long_outlined,
                        size: 56,
                        color: AppColors.paleOak,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        _vueVentes
                            ? 'Aucune vente pour l\'instant'
                            : 'Aucun achat pour l\'instant',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.rosyTaupe,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.stackLg,
                  AppSpacing.containerMargin,
                  40,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    groupes.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.stackMd, top: 8),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: AppTextStyles.labelCaps,
                          ),
                        ),
                        ...entry.value.map((t) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.stackMd),
                          child: _buildItem(t),
                        )),
                      ];
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelecteurItem({
    required String label,
    required bool actif,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: actif ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: actif ? Colors.white : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> transaction) {
    final statut = transaction['statut'] as String;
    final prix = (transaction['prix_final'] as num).toDouble();
    final annonce = transaction['annonces'] as Map<String, dynamic>?;
    final titre = annonce?['titre'] ?? 'Article';
    final images = (annonce?['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl = images.isNotEmpty
        ? images.first['url_image'] as String
        : null;
    final transactionId = transaction['id'] as int;
    final annonceId = transaction['annonce_id'] as int;
    final estLiquide = (transaction['paiements'] is List &&
        (transaction['paiements'] as List).isNotEmpty)
        ? (transaction['paiements'] as List).first['methode'] == 'liquide'
        : false;

    final couleurStatut = _couleurStatut(statut);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuiviTransactionScreen(
              transactionId: transactionId,
              annonceId: annonceId,
              estLiquide: estLiquide,
            ),
          ),
        );
        _charger();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
          border: Border(
            left: BorderSide(color: couleurStatut, width: 3),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 56,
                height: 56,
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
                    titre,
                    style: AppTextStyles.titleMd.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _libelleStatut(statut),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: couleurStatut,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${prix.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.paleOak, size: 18),
          ],
        ),
      ),
    );
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'en_sequestre':
        return Colors.blue;
      case 'en_livraison':
        return Colors.orange;
      case 'completee':
        return AppColors.emerald;
      case 'litige':
        return AppColors.error;
      case 'remboursee':
        return Colors.purple;
      default:
        return AppColors.rosyTaupe;
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'en_sequestre':
        return 'En séquestre';
      case 'en_livraison':
        return 'En livraison';
      case 'completee':
        return 'Terminée';
      case 'litige':
        return 'Litige';
      case 'remboursee':
        return 'Remboursée';
      default:
        return statut;
    }
  }
}