import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../avis/avis_screen.dart';
import '../../services/message_service.dart';
import '../messages/chat_screen.dart';

class PaiementScreen extends StatefulWidget {
  final int annonceId;
  final String vendeurId;
  final String titreAnnonce;
  final double montant;
  final String? imageUrl;

  const PaiementScreen({
    super.key,
    required this.annonceId,
    required this.vendeurId,
    required this.titreAnnonce,
    required this.montant,
    this.imageUrl,
  });

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  final _service = TransactionService();
  String? _methodeSelectionnee;
  bool _loading = false;

  // Free Money retiré (plus disponible) — Wave et Orange Money utilisent
  // les logos locaux déjà déclarés dans pubspec.yaml.
  final List<Map<String, dynamic>> _methodes = [
    {
      'id': 'wave',
      'nom': 'Wave',
      'asset': 'assets/images/wave.png',
      'lettre': 'W',
      'couleur': const Color(0xFF1E90FF),
      'type': 'mobile',
    },
    {
      'id': 'orange_money',
      'nom': 'Orange Money',
      'asset': 'assets/images/orange.png',
      'lettre': 'O',
      'couleur': const Color(0xFFFF6600),
      'type': 'mobile',
    },
    {
      'id': 'liquide',
      'nom': 'Cash',
      'asset': null,
      'icon': Icons.payments_outlined,
      'couleur': AppColors.navy,
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
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softBlush,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.navy, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Paiement', style: AppTextStyles.titleMd),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('RÉSUMÉ DE LA COMMANDE'),
            const SizedBox(height: AppSpacing.stackSm),
            _buildResume(),

            const SizedBox(height: AppSpacing.stackLg),
            _buildSecurityBadge(),

            const SizedBox(height: AppSpacing.stackLg + 8),
            _buildLabel('MODE DE PAIEMENT'),
            const SizedBox(height: AppSpacing.stackSm),
            _buildPaymentGrid(),

            const SizedBox(height: AppSpacing.stackLg),
            if (_methodeSelectionnee != null) _buildInfoMethode(),

            const SizedBox(height: AppSpacing.stackLg),
            const Divider(color: AppColors.paleOak),
            const SizedBox(height: AppSpacing.stackMd),
            _buildPriceRow('Montant à payer',
                '${widget.montant.toStringAsFixed(0)} FCFA',
                accent: true),

            const SizedBox(height: AppSpacing.stackLg + 8),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(text, style: AppTextStyles.labelCaps),
    );
  }

  Widget _buildResume() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softBlush,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: widget.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: Icon(Icons.shopping_bag_outlined,
                      color: AppColors.primary, size: 20),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.shopping_bag_outlined,
                      color: AppColors.primary, size: 20),
                ),
              )
                  : const Center(
                child: Icon(Icons.shopping_bag_outlined,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.titreAnnonce,
              style: AppTextStyles.titleMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${widget.montant.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.emerald.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: const Border(
          left: BorderSide(color: AppColors.emerald, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.emerald, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement sécurisé par séquestre',
                  style: AppTextStyles.titleMd.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'L\'argent est conservé par Rizen et ne sera versé '
                      'au vendeur qu\'une fois que vous aurez validé la '
                      'réception du produit.',
                  style: AppTextStyles.bodySm.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _methodes.length == 3 ? 3 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: _methodes.map((m) => _buildPaymentCard(m)).toList(),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> m) {
    final selected = _methodeSelectionnee == m['id'];
    final couleur = m['couleur'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _methodeSelectionnee = m['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: couleur,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: m['asset'] != null
                    ? ClipOval(
                  child: Image.asset(
                    m['asset'] as String,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text(
                      m['lettre'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                    : Icon(m['icon'] as IconData,
                    color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              m['nom'] as String,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMethode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softBlush,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _estLiquide
                  ? 'Le montant sera remis en espèces au livreur. La '
                  'transaction sera confirmée par le vendeur à réception.'
                  : 'Le paiement sera simulé et placé en séquestre '
                  'jusqu\'à confirmation de réception.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: accent
              ? AppTextStyles.titleMd.copyWith(fontSize: 16)
              : AppTextStyles.bodyMd,
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: accent ? 22 : 15,
            fontWeight: accent ? FontWeight.w800 : FontWeight.w600,
            color: accent ? AppColors.primary : AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed:
        _loading || _methodeSelectionnee == null ? null : _payer,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.paleOak,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _estLiquide
                  ? 'Confirmer la commande'
                  : 'Confirmer le paiement',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20),
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

  Future<void> _contacterAutrePartie() async {
    final acheteurId = _transaction?['acheteur_id'] as String?;
    final vendeurId = _transaction?['vendeur_id'] as String?;
    final userId = _userId;
    if (acheteurId == null || vendeurId == null || userId == null) return;

    final titre =
    (_transaction?['annonces']?['titre'] ?? 'Article') as String;

    try {
      final convId = await MessageService().getOrCreateConversation(
        annonceId: widget.annonceId,
        userId: userId,
        vendeurId: vendeurId,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              annonceTitre: titre,
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
    }
  }

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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AvisScreen(
                acheteurId: acheteurId,
                vendeurId: vendeurId,
                destinataireNom: nomVendeur,
                transactionId: widget.transactionId,
                emetteur: 'acheteur',
                titreAnnonce:
                (_transaction?['annonces']?['titre']) as String?,
              ),
            ),
          );
        }

        if (_estVendeur) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AvisScreen(
                acheteurId: acheteurId,
                vendeurId: vendeurId,
                destinataireNom: nomAcheteur,
                transactionId: widget.transactionId,
                emetteur: 'vendeur',
                titreAnnonce:
                (_transaction?['annonces']?['titre']) as String?,
              ),
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
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final titre =
    (_transaction?['annonces']?['titre'] ?? 'Article') as String;
    final prix =
        (_transaction?['prix_final'] as num?)?.toDouble() ?? 0;
    final images =
        (_transaction?['annonces']?['images_annonce'] as List<dynamic>?) ??
            [];
    final imageUrl =
    images.isNotEmpty ? images.first['url_image'] as String? : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Suivi de commande', style: AppTextStyles.headlineSm),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _charger,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResumeCard(titre, prix, imageUrl),
              const SizedBox(height: AppSpacing.stackLg),
              _buildDeliveryStatusCard(),
              const SizedBox(height: AppSpacing.stackLg),
              _buildActions(),
              const SizedBox(height: AppSpacing.stackLg),
              _buildContactButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte résumé : image, titre, statut ponctué ──
  Widget _buildResumeCard(String titre, double prix, String? imageUrl) {
    final couleurStatut = _couleurStatut(_statut);
    final labelStatut = _labelStatut(_statut);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.softBlush,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    color: AppColors.paleOak),
              )
                  : const Icon(Icons.image_outlined,
                  color: AppColors.paleOak),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMANDE #${widget.transactionId}',
                  style: AppTextStyles.labelCaps,
                ),
                const SizedBox(height: 4),
                Text(
                  titre,
                  style: AppTextStyles.titleMd.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${prix.toStringAsFixed(0)} FCFA',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: couleurStatut,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labelStatut,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: couleurStatut,
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

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'en_sequestre':
        return Colors.blue;
      case 'en_livraison':
        return Colors.orange;
      case 'completee':
        return AppColors.emerald;
      case 'litige':
        return Colors.red;
      case 'remboursee':
        return Colors.purple;
      default:
        return AppColors.rosyTaupe;
    }
  }

  String _labelStatut(String statut) {
    switch (statut) {
      case 'en_sequestre':
        return 'Paiement sécurisé';
      case 'en_livraison':
        return 'En livraison';
      case 'completee':
        return 'Terminée';
      case 'litige':
        return 'Litige ouvert';
      case 'remboursee':
        return 'Remboursée';
      default:
        return statut;
    }
  }

  // ── Timeline verticale connectée ──
  Widget _buildDeliveryStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('État de la commande', style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.stackLg),
          _buildTimeline(),
        ],
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
        final fait = indexActuel > index ||
            (indexActuel == index && _statut == 'completee');
        final actuel = indexActuel == index && !fait;
        final isLast = index == etapes.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: fait
                          ? AppColors.primary
                          : actuel
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.paleOak.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: actuel
                          ? Border.all(
                          color: AppColors.primary, width: 3)
                          : null,
                    ),
                    child: fait
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 15)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: fait
                            ? AppColors.primary
                            : AppColors.paleOak.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text(
                    etape['label'] as String,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: (fait || actuel)
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: (fait || actuel)
                          ? AppColors.navy
                          : AppColors.rosyTaupe,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    if (_actionEnCours) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
              couleur: Colors.red.shade600,
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
          color: AppColors.emerald.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.emerald),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Transaction terminée avec succès !',
                style: AppTextStyles.titleMd.copyWith(
                  fontSize: 14,
                  color: AppColors.emerald,
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
    final c = couleur ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
          elevation: 0,
        ),
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Contacter l'autre partie (fonctionnel : ouvre le chat) ──
  Widget _buildContactButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _contacterAutrePartie,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
        ),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(
          _estVendeur ? "Contacter l'acheteur" : 'Contacter le vendeur',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}