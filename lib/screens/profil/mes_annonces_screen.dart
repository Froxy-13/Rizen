import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';

class MesAnnoncesScreen extends StatefulWidget {
  const MesAnnoncesScreen({super.key});

  @override
  State<MesAnnoncesScreen> createState() => _MesAnnoncesScreenState();
}

class _MesAnnoncesScreenState extends State<MesAnnoncesScreen> {
  final _service = ProfilService();
  List<Map<String, dynamic>> _annonces = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final annonces = await _service.getMesAnnonces();
    setState(() {
      _annonces = annonces;
      _loading = false;
    });
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
          'Mes annonces',
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
          : _annonces.isEmpty
          ? Center(
        child: Text(
          'Aucune annonce publiée',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: AppColors.rosyTaupe,
          ),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _annonces.length,
        itemBuilder: (context, index) {
          final annonce = _annonces[index];
          final images =
          (annonce['images_annonce'] as List<dynamic>? ?? [])
              .map((e) => e['url_image'] as String)
              .toList();
          final imageUrl =
          images.isNotEmpty ? images.first : null;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailAnnonceScreen(
                    annonceId: annonce['id'] as int),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.paleOak),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: imageUrl != null
                          ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: AppColors.softBlush,
                        child: Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.paleOak),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          annonce['titre'] ?? '',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}