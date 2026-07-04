import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';

class CreerAnnonceScreen extends StatefulWidget {
  const CreerAnnonceScreen({super.key});

  @override
  State<CreerAnnonceScreen> createState() => _CreerAnnonceScreenState();
}

class _CreerAnnonceScreenState extends State<CreerAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AnnonceService();
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _categorieId;
  List<File> _images = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    final cats = await _service.getCategories();
    setState(() => _categories = cats);
  }

  Future<void> _ajouterImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _supprimerImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      // Upload images
      final urls = <String>[];
      for (final img in _images) {
        final url = await _service.uploadImage(img.path);
        urls.add(url);
      }

      // Créer l'annonce
      await _service.creerAnnonce(
        titre: _titreController.text.trim(),
        description: _descController.text.trim(),
        prix: double.parse(_prixController.text.trim()),
        categorieId: _categorieId!,
        ville: _villeController.text.trim(),
        quartier: _quartierController.text.trim(),
        userId: userId,
        urlsImages: urls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce publiée avec succès')),
        );
        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _titreController.clear();
        _descController.clear();
        _prixController.clear();
        _villeController.clear();
        _quartierController.clear();
        setState(() {
          _images = [];
          _categorieId = null;
        });
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
          'Nouvelle annonce',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos
              _buildLabel('Photos (optionnel, max 5)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Bouton ajouter
                    GestureDetector(
                      onTap: _ajouterImage,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.softBlush,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.paleOak),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.dustyRose, size: 28),
                            const SizedBox(height: 4),
                            Text('Ajouter',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  color: AppColors.dustyRose,
                                )),
                          ],
                        ),
                      ),
                    ),
                    // Images sélectionnées
                    ..._images.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _supprimerImage(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close,
                                    size: 14, color: AppColors.mauveShadow),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Titre
              _buildLabel('Titre'),
              const SizedBox(height: 8),
              _buildField(
                controller: _titreController,
                hint: 'Ex: iPhone 13 Pro Max',
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 16),

              // Prix
              _buildLabel('Prix (FCFA)'),
              const SizedBox(height: 8),
              _buildField(
                controller: _prixController,
                hint: 'Ex: 150000',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (double.tryParse(v) == null) return 'Prix invalide';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Catégorie
              _buildLabel('Catégorie'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _categorieId,
                hint: Text('Choisir une catégorie',
                    style: TextStyle(
                        color: AppColors.rosyTaupe, fontSize: 14)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.paleOak),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.paleOak),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.dustyRose),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['nom'],
                      style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14)),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _categorieId = v),
              ),

              const SizedBox(height: 16),

              // Description
              _buildLabel('Description'),
              const SizedBox(height: 8),
              _buildField(
                controller: _descController,
                hint: 'Décrivez votre article...',
                maxLines: 4,
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 16),

              // Ville
              _buildLabel('Ville'),
              const SizedBox(height: 8),
              _buildField(
                controller: _villeController,
                hint: 'Ex: Dakar',
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 16),

              // Quartier
              _buildLabel('Quartier'),
              const SizedBox(height: 8),
              _buildField(
                controller: _quartierController,
                hint: 'Ex: Plateau',
              ),
            ],
          ),
        ),
      ),

      // Bouton publier
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        color: AppColors.white,
        child: ElevatedButton(
          onPressed: _loading ? null : _publier,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mauveShadow,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : const Text(
            'Publier l\'annonce',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.rosyTaupe, fontSize: 14),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.paleOak),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.paleOak),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.dustyRose),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}