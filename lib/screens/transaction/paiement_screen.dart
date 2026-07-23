import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../avis/avis_screen.dart';

class PaiementScreen extends StatefulWidget {
  final int annonceId;
  final String vendeurId;
  final String titreAnnonce;
  final double montant;

  const PaiementScreen({
    super.key,
    required this.annonceId,
    required this.vendeurId,
    required this.titreAnnonce,
    required this.montant,
  });

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  final _service = TransactionService();
  String? _methodeSelectionnee;
  bool _loading = false;

  final List<Map<String, dynamic>> _methodes = [
    {
      'id': 'wave',
      'nom': 'Wave',
      'icon': Icons.waves,
      'couleur': const Color(0xFF1E90FF),
      'type': 'mobile',
    },
    {
      'id': 'orange_money',
      'nom': 'Orange Money',
      'icon': Icons.phone_android,
      'couleur': const Color(0xFFFF6600),
      'type': 'mobile',
    },
    {
      'id': 'free_money',
      'nom': 'Free Money',
      'icon': Icons.mobile_friendly,
      'couleur': const Color(0xFF00AA00),
      'type': 'mobile',
    },
    {
      'id': 'liquide',
      'nom': 'Espèces (remise en main propre)',
      'icon': Icons.payments_outlined,
      'couleur': const Color(0xFF744253),
      'type': 'liquide',
    },
  ];

  bool get _estLiquide =>
      _methodes.firstWhere(
            (m) => m['id'] == _methodeSelectionnee,
        orElse: () => {'type': ''},
      )['type'] ==
          'liquide';

  Future<void> _payer() async {
    if (_methodeSelectionnee == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      int transactionId;

      if (_estLiquide) {
        transactionId = await _service.creerTransactionLiquide(
          annonceId: widget.annonceId,
          acheteurId: userId,
          vendeurId: widget.vendeurId,
          montant: widget.montant,
        );
      } else {
        transactionId = await _service.simulerPaiementMobile(
          annonceId: widget.annonceId,
          acheteurId: userId,
          vendeurId: widget.vendeurId,
          montant: widget.montant,
          methode: _methodeSelectionnee!,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuiviTransactionScreen(
              transactionId: transactionId,
              annonceId: widget.annonceId,
              estLiquide: _estLiquide,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paiement',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé commande
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.paleOak),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softBlush,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_bag_outlined,
                        color: AppColors.dustyRose, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titreAnnonce,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.montant.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mauveShadow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Choisissez votre méthode de paiement',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Méthodes de paiement
            ...(_methodes.map((m) {
              final selected = _methodeSelectionnee == m['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _methodeSelectionnee = m['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.softBlush
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.dustyRose
                          : AppColors.paleOak,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (m['couleur'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          color: m['couleur'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m['nom'] as String,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle,
                            color: AppColors.dustyRose, size: 20),
                    ],
                  ),
                ),
              );
            }).toList()),

            const SizedBox(height: 16),

            // Info selon méthode
            if (_methodeSelectionnee != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softBlush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.dustyRose, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _estLiquide
                            ? 'Le montant sera remis en espèces au livreur. La transaction sera confirmée par le vendeur à réception.'
                            : 'Le paiement sera simulé et placé en séquestre jusqu\'à confirmation de réception.',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: AppColors.dustyRose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Bouton payer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading || _methodeSelectionnee == null
                    ? null
                    : _payer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mauveShadow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: AppColors.paleOak,
                ),
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  _estLiquide
                      ? 'Confirmer la commande'
                      : 'Payer ${widget.montant.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Écran de suivi de transaction
// ─────────────────────────────────────────────

class SuiviTransactionScreen extends StatefulWidget {
  final int transactionId;
  final int annonceId;
  final bool estLiquide;

  const SuiviTransactionScreen({
    super.key,
    required this.transactionId,
    required this.annonceId,
    required this.estLiquide,
  });

  @override
  State<SuiviTransactionScreen> createState() =>
      _SuiviTransactionScreenState();
}

class _SuiviTransactionScreenState extends State<SuiviTransactionScreen> {
  final _service = TransactionService();
  Map<String, dynamic>? _transaction;
  bool _loading = true;
  bool _actionEnCours = false;
  final _userId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await _service.getTransaction(widget.transactionId);
    setState(() {
      _transaction = data;
      _loading = false;
    });
  }

  bool get _estAcheteur => _transaction?['acheteur_id'] == _userId;
  bool get _estVendeur => _transaction?['vendeur_id'] == _userId;
  String get _statut => _transaction?['statut'] ?? '';

  Future<void> _action(String type) async {
    setState(() => _actionEnCours = true);
    try {
      if (type == 'envoi') {
        await _service.confirmerEnvoi(widget.transactionId);
        await _charger();
      } else if (type == 'reception') {
        await _service.confirmerReception(
            widget.transactionId, widget.annonceId);
        await _charger();

        final transaction =
        await _service.getTransaction(widget.transactionId);
        final acheteurId = transaction?['acheteur_id'] as String?;
        final vendeurId = transaction?['vendeur_id'] as String?;

        if (acheteurId == null || vendeurId == null || !mounted) return;

        final acheteurData = await Supabase.instance.client
            .from('profils')
            .select('nom, prenom')
            .eq('id', acheteurId)
            .maybeSingle();
        final vendeurData = await Supabase.instance.client
            .from('profils')
            .select('nom, prenom')
            .eq('id', vendeurId)
            .maybeSingle();

        final nomAcheteur = acheteurData != null
            ? '${acheteurData['prenom']} ${acheteurData['nom']}'
            : 'l\'acheteur';
        final nomVendeur = vendeurData != null
            ? '${vendeurData['prenom']} ${vendeurData['nom']}'
            : 'le vendeur';

        if (!mounted) return;

        if (_estAcheteur) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AvisDialog(
              acheteurId: acheteurId,
              vendeurId: vendeurId,
              destinataireNom: nomVendeur,
              transactionId: widget.transactionId,
              emetteur: 'acheteur',
            ),
          );
        }

        if (_estVendeur) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AvisDialog(
              acheteurId: acheteurId,
              vendeurId: vendeurId,
              destinataireNom: nomAcheteur,
              transactionId: widget.transactionId,
              emetteur: 'vendeur',
            ),
          );
        }
        return;
      } else if (type == 'litige') {
        await _service.ouvrirLitige(widget.transactionId);
        await _charger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.dustyRose)),
      );
    }

    final titre =
    (_transaction?['annonces']?['titre'] ?? 'Article') as String;
    final prix =
        (_transaction?['prix_final'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Suivi de commande',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.dustyRose,
        onRefresh: _charger,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.paleOak),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prix.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mauveShadow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatutBadge(_statut),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Progression',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeline(),

              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color couleur;
    String label;
    switch (statut) {
      case 'en_sequestre':
        couleur = Colors.blue;
        label = 'En séquestre';
        break;
      case 'en_livraison':
        couleur = Colors.orange;
        label = 'En livraison';
        break;
      case 'completee':
        couleur = Colors.green;
        label = 'Terminée';
        break;
      case 'litige':
        couleur = Colors.red;
        label = 'Litige';
        break;
      case 'remboursee':
        couleur = Colors.purple;
        label = 'Remboursée';
        break;
      default:
        couleur = Colors.grey;
        label = statut;
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final etapes = widget.estLiquide
        ? [
      {'statut': 'en_livraison', 'label': 'Commande confirmée'},
      {'statut': 'completee', 'label': 'Paiement reçu'},
    ]
        : [
      {'statut': 'en_sequestre', 'label': 'Paiement sécurisé'},
      {'statut': 'en_livraison', 'label': 'Article envoyé'},
      {'statut': 'completee', 'label': 'Réception confirmée'},
    ];

    final ordre = widget.estLiquide
        ? ['en_livraison', 'completee']
        : ['en_sequestre', 'en_livraison', 'completee'];

    final indexActuel = ordre.indexOf(_statut);

    return Column(
      children: etapes.asMap().entries.map((entry) {
        final index = entry.key;
        final etape = entry.value;
        final fait = indexActuel >= index;
        final actuel = indexActuel == index;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: fait
                        ? AppColors.mauveShadow
                        : AppColors.paleOak,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    fait ? Icons.check : Icons.circle_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                if (index < etapes.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    color: fait
                        ? AppColors.mauveShadow
                        : AppColors.paleOak,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                etape['label'] as String,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: actuel
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: fait
                      ? AppColors.onSurface
                      : AppColors.rosyTaupe,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    if (_actionEnCours) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.dustyRose),
      );
    }

    if (!widget.estLiquide) {
      if (_statut == 'en_sequestre' && _estVendeur) {
        return _buildBoutonAction(
          label: "Confirmer l'envoi",
          icon: Icons.local_shipping_outlined,
          onTap: () => _action('envoi'),
        );
      }
      if (_statut == 'en_livraison' && _estAcheteur) {
        return Column(
          children: [
            _buildBoutonAction(
              label: 'Confirmer la réception',
              icon: Icons.check_circle_outline,
              onTap: () => _action('reception'),
            ),
            const SizedBox(height: 10),
            _buildBoutonAction(
              label: 'Ouvrir un litige',
              icon: Icons.report_outlined,
              couleur: AppColors.dustyRose,
              onTap: () => _action('litige'),
            ),
          ],
        );
      }
    }

    if (widget.estLiquide) {
      if (_statut == 'en_livraison' && _estVendeur) {
        return _buildBoutonAction(
          label: 'Confirmer la réception du paiement',
          icon: Icons.payments_outlined,
          onTap: () => _action('reception'),
        );
      }
    }

    if (_statut == 'completee') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Transaction terminée avec succès !',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBoutonAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? couleur,
  }) {
    final c = couleur ?? AppColors.mauveShadow;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}