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
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  final _userId = Supabase.instance.client.auth.currentUser?.id;

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
          'Mes transactions',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.dustyRose))
          : _transactions.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.paleOak),
            const SizedBox(height: 12),
            Text(
              'Aucune transaction',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppColors.rosyTaupe,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: AppColors.dustyRose,
        onRefresh: _charger,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _transactions.length,
          itemBuilder: (context, index) =>
              _buildItem(_transactions[index]),
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
    final paiements = transaction['paiements'];
    final methode = paiements is List && paiements.isNotEmpty
        ? paiements.first['methode'] as String
        : '';
    final estAcheteur = transaction['acheteur_id'] == _userId;
    final transactionId = transaction['id'] as int;
    final annonceId = transaction['annonce_id'] as int;

    // Détecter si liquide
    final estLiquide = methode == 'liquide';

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paleOak),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                child: Icon(Icons.image_outlined,
                    color: AppColors.paleOak),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
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
                    '${prix.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mauveShadow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatutBadge(statut),
                      const SizedBox(width: 8),
                      Text(
                        estAcheteur ? 'Acheteur' : 'Vendeur',
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
            ),

            Icon(Icons.chevron_right, color: AppColors.paleOak),
          ],
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
        label = 'Séquestre';
        break;
      case 'en_livraison':
        couleur = Colors.orange;
        label = 'Livraison';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }
}