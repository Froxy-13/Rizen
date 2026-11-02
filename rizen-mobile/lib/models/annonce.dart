class Annonce {
  final int id;
  final String titre;
  final double prixActuel;
  final String? ville;
  final String? quartier;
  final String statut;
  final String utilisateurId;
  final int? categorieId;
  final DateTime datePublication;
  final List<String> images;

  Annonce({
    required this.id,
    required this.titre,
    required this.prixActuel,
    this.ville,
    this.quartier,
    required this.statut,
    required this.utilisateurId,
    this.categorieId,
    required this.datePublication,
    this.images = const [],
  });

  factory Annonce.fromMap(Map<String, dynamic> map) {
    final imagesRaw = map['images_annonce'] as List<dynamic>? ?? [];
    return Annonce(
      id: map['id'],
      titre: map['titre'],
      prixActuel: (map['prix_actuel'] as num).toDouble(),
      ville: map['ville'],
      quartier: map['quartier'],
      statut: map['statut'] ?? 'active',
      utilisateurId: map['utilisateur_id'],
      categorieId: map['categorie_id'],
      datePublication: DateTime.parse(map['date_publication']),
      images: imagesRaw
          .map((img) => img['url_image'] as String)
          .toList(),
    );
  }
}