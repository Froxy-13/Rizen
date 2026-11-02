import { createClient } from "@supabase/supabase-js";

export function createServerClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false } }
  );
}

// ─── Types ────────────────────────────────────────────────────────────

export interface DBCategorie {
  id: number;
  nom: string;
}

export interface DBAnnonceWithDetails {
  id: number;
  titre: string;
  prix_actuel: number;
  ville: string | null;
  quartier: string | null;
  date_publication: string;
  utilisateur_id: string;
  firstImageUrl: string | null;
  vendeur: {
    prenom: string | null;
    nom: string | null;
    photo: string | null;
  } | null;
}

export interface DBTopSeller {
  id: string;
  prenom: string | null;
  nom: string | null;
  photo: string | null;
  adresse: string | null;
  note_moyenne: number;
  avis_count: number;
  annonces_count: number;
}

export interface DBStats {
  annonces_actives: number;
  vendeurs_actifs: number;
}

// ─── Fonctions de fetch ───────────────────────────────────────────────

export async function fetchStats(): Promise<DBStats> {
  try {
    const supabase = createServerClient();
    const [annoncesRes, vendeursRes] = await Promise.all([
      supabase
        .from("annonces")
        .select("id", { count: "exact", head: true })
        .eq("statut", "active"),
      supabase
        .from("profils")
        .select("id", { count: "exact", head: true })
        .not("prenom", "is", null),
    ]);
    return {
      annonces_actives: annoncesRes.count ?? 0,
      vendeurs_actifs: vendeursRes.count ?? 0,
    };
  } catch {
    return { annonces_actives: 0, vendeurs_actifs: 0 };
  }
}

export async function fetchCategories(): Promise<DBCategorie[]> {
  try {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("categories")
      .select("id, nom")
      .order("id")
      .limit(8);
    if (error) throw error;
    return data || [];
  } catch {
    return [];
  }
}

export async function fetchRecentAnnonces(): Promise<DBAnnonceWithDetails[]> {
  try {
    const supabase = createServerClient();

    const { data: annonces, error } = await supabase
      .from("annonces")
      .select("id, titre, prix_actuel, ville, quartier, date_publication, utilisateur_id")
      .eq("statut", "active")
      .order("date_publication", { ascending: false })
      .limit(4);

    if (error || !annonces?.length) return [];

    // Première image par annonce
    const ids = annonces.map((a) => a.id);
    const { data: images } = await supabase
      .from("images_annonce")
      .select("annonce_id, url_image, ordre")
      .in("annonce_id", ids)
      .order("ordre", { ascending: true });

    // Profils des vendeurs (profils.id = auth.users.id)
    const utilisateurIdsSet = new Set(
      annonces.map((a) => a.utilisateur_id).filter(Boolean)
    );
    const utilisateurIds = Array.from(utilisateurIdsSet);
    const { data: profils } = await supabase
      .from("profils")
      .select("id, prenom, nom, photo")
      .in("id", utilisateurIds);

    return annonces.map((annonce) => {
      const annonceImages = (images || [])
        .filter((img) => img.annonce_id === annonce.id)
        .sort((a, b) => (a.ordre ?? 0) - (b.ordre ?? 0));
      const profil = (profils || []).find((p) => p.id === annonce.utilisateur_id);
      return {
        ...annonce,
        firstImageUrl: annonceImages[0]?.url_image ?? null,
        vendeur: profil
          ? { prenom: profil.prenom, nom: profil.nom, photo: profil.photo }
          : null,
      };
    });
  } catch {
    return [];
  }
}

export async function fetchTopSellers(): Promise<DBTopSeller[]> {
  try {
    const supabase = createServerClient();

    const [profisRes, avisRes, annoncesRes] = await Promise.all([
      supabase
        .from("profils")
        .select("id, prenom, nom, photo, adresse")
        .not("prenom", "is", null)
        .limit(20),
      supabase
        .from("avis")
        .select("vendeur_id, note")
        .eq("emetteur", "acheteur"),
      supabase
        .from("annonces")
        .select("utilisateur_id")
        .eq("statut", "active"),
    ]);

    const profils = profisRes.data || [];
    const avis = avisRes.data || [];
    const annonces = annoncesRes.data || [];

    return profils
      .map((p) => {
        const sellerAvis = avis.filter((a) => a.vendeur_id === p.id);
        const noteMoyenne =
          sellerAvis.length > 0
            ? sellerAvis.reduce((s, a) => s + (a.note ?? 0), 0) / sellerAvis.length
            : 0;
        const annoncesCount = annonces.filter(
          (a) => a.utilisateur_id === p.id
        ).length;
        return {
          id: p.id,
          prenom: p.prenom,
          nom: p.nom,
          photo: p.photo,
          adresse: p.adresse,
          note_moyenne: Math.round(noteMoyenne * 10) / 10,
          avis_count: sellerAvis.length,
          annonces_count: annoncesCount,
        };
      })
      .filter((s) => s.annonces_count > 0 || s.avis_count > 0)
      .sort(
        (a, b) =>
          b.note_moyenne - a.note_moyenne || b.avis_count - a.avis_count
      )
      .slice(0, 3);
  } catch {
    return [];
  }
}
