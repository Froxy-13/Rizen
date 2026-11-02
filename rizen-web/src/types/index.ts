// ── Types TypeScript Rizen ──
// Miroir des modèles Flutter / tables Supabase

export interface Profil {
  id: string;
  nom: string;
  prenom: string;
  email?: string;
  telephone?: string;
  adresse?: string;
  photo?: string;
  role: "user" | "superadmin";
  statut: "actif" | "suspendu";
  created_at: string;
}

export interface Categorie {
  id: number;
  nom: string;
  nombreAnnonces?: number;
}

export interface ImageAnnonce {
  id: number;
  annonce_id: number;
  url_image: string;
  ordre: number;
}

export type StatutAnnonce = "active" | "suspendue" | "vendue";

export interface Annonce {
  id: number;
  titre: string;
  description?: string;
  prix_initial: number;
  prix_actuel: number;
  ville?: string;
  quartier?: string;
  statut: StatutAnnonce;
  utilisateur_id: string;
  categorie_id?: number;
  date_publication: string;
  images_annonce?: ImageAnnonce[];
  profils?: Pick<Profil, "nom" | "prenom" | "photo">;
  categories?: Pick<Categorie, "nom">;
}

export type StatutNegociation = "en_attente" | "acceptee" | "refusee";

export interface Negociation {
  id: number;
  annonce_id: number;
  acheteur_id: string;
  vendeur_id: string;
  prix_propose: number;
  statut: StatutNegociation;
  conversation_id: number;
  message?: string;
  created_at: string;
}

export type StatutTransaction =
  | "en_sequestre"
  | "en_livraison"
  | "completee"
  | "remboursee"
  | "litige";

export interface Transaction {
  id: number;
  annonce_id: number;
  acheteur_id: string;
  vendeur_id: string;
  prix_final: number;
  statut: StatutTransaction;
  motif_litige?: string;
  created_at: string;
  annonces?: Pick<Annonce, "titre" | "images_annonce">;
}

export interface Message {
  id: number;
  conversation_id: number;
  sender_id: string;
  contenu: string;
  type: "texte" | "negociation" | "transaction";
  lu: boolean;
  date_envoi: string;
  negociation_id?: number;
  transaction_id?: number;
}

export interface Avis {
  id: number;
  vendeur_id: string;
  note: number;
  commentaire?: string;
  emetteur: "acheteur" | "vendeur";
  created_at: string;
}

export interface Signalement {
  id: number;
  annonce_id: number;
  utilisateur_id: string;
  raison: string;
  description?: string;
  statut: "en_attente" | "traite" | "rejete";
  created_at: string;
}

// ── Types UI ──

export interface FiltresDecouvrir {
  categorieId?: number;
  prixMin?: number;
  prixMax?: number;
  ville?: string;
  quartier?: string;
  etat?: string;
  recherche?: string;
  tri?: "recent" | "prix_asc" | "prix_desc";
}

export interface StatsDashboard {
  utilisateurs: number;
  annoncesActives: number;
  transactionsMois: number;
  volumeTotal: number;
  croissanceUtilisateurs?: number;
  croissanceAnnonces?: number;
  litiges: number;
}
