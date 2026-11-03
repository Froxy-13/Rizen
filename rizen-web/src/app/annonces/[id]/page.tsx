import React from "react";
import Link from "next/link";
import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { NavbarDecouvrir } from "@/components/layout/NavbarDecouvrir";
import { ListingGallery } from "@/components/ui/ListingGallery";
import { SellerStickyCard, SellerInfo } from "@/components/ui/SellerStickyCard";
import { ListingCard, Listing } from "@/components/ui/ListingCard";
import { MapPin, Clock, Check, ChevronRight } from "lucide-react";

// ── helpers ──────────────────────────────────────────────────────────────

function timeAgo(date: string): string {
  const diff = Date.now() - new Date(date).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `Il y a ${Math.max(1, mins)}min`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `Il y a ${hours}h`;
  const days = Math.floor(hours / 24);
  if (days === 1) return "Hier";
  return `Il y a ${days}j`;
}

function memberSince(date: string): string {
  return new Date(date).toLocaleDateString("fr-FR", { month: "long", year: "numeric" });
}

const PLACEHOLDER_IMG = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=1000&auto=format&fit=crop";
const PLACEHOLDER_AVATAR = "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop";

// ── fetch ────────────────────────────────────────────────────────────────

async function getAnnonceData(id: string) {
  const cookieStore = await cookies();

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll(); },
        setAll() {},
      },
    }
  );

  // Annonce + images + categorie
  const { data: annonce } = await supabase
    .from("annonces")
    .select("id, titre, description, prix_actuel, prix_initial, ville, quartier, statut, utilisateur_id, categorie_id, date_publication, images_annonce(url_image, ordre), categories(nom)")
    .eq("id", Number(id))
    .maybeSingle();

  if (!annonce || annonce.statut === "suspendue") return null;

  // Profil vendeur
  const { data: vendeurProfil } = await supabase
    .from("profils")
    .select("id, nom, prenom, photo, telephone, created_at")
    .eq("id", annonce.utilisateur_id)
    .maybeSingle();

  // Avis du vendeur
  const { data: avisData } = await supabase
    .from("avis")
    .select("note")
    .eq("vendeur_id", annonce.utilisateur_id)
    .eq("emetteur", "acheteur");

  const avis = avisData ?? [];
  const rating = avis.length > 0
    ? Math.round((avis.reduce((s, a) => s + (a.note ?? 0), 0) / avis.length) * 10) / 10
    : 0;

  // Nombre d'annonces actives du vendeur
  const { count: sellerListingsCount } = await supabase
    .from("annonces")
    .select("id", { count: "exact", head: true })
    .eq("utilisateur_id", annonce.utilisateur_id)
    .eq("statut", "active")
    .neq("id", annonce.id);

  // Annonces similaires (même catégorie)
  type SimilarRow = { id: number; titre: string; prix_actuel: number; ville: string | null; quartier: string | null; date_publication: string; utilisateur_id: string; images_annonce: { url_image: string; ordre: number }[] };
  let similarRaw: SimilarRow[] = [];
  if (annonce.categorie_id) {
    const { data } = await supabase
      .from("annonces")
      .select("id, titre, prix_actuel, ville, quartier, date_publication, utilisateur_id, images_annonce(url_image, ordre)")
      .eq("statut", "active")
      .eq("categorie_id", annonce.categorie_id)
      .neq("id", annonce.id)
      .order("date_publication", { ascending: false })
      .limit(4);
    similarRaw = (data ?? []) as SimilarRow[];
  }

  // Profils vendeurs des similaires
  const simUids = Array.from(new Set(similarRaw.map((a: { utilisateur_id: string }) => a.utilisateur_id)));
  const { data: simProfils } = simUids.length
    ? await supabase.from("profils").select("id, prenom, nom, photo").in("id", simUids)
    : { data: [] };

  const simProfilsMap = new Map(
    (simProfils ?? []).map((p: { id: string; prenom: string | null; nom: string | null; photo: string | null }) => [p.id, p])
  );

  // Utilisateur connecté (pour savoir si c'est sa propre annonce)
  const { data: { user } } = await supabase.auth.getUser();

  // Prix négocié et accepté pour cet acheteur (personnalisé, invisible aux autres)
  let prixNegocie: number | null = null;
  if (user && user.id !== annonce.utilisateur_id) {
    const { data: negoAcceptee } = await supabase
      .from("negociations")
      .select("prix_propose")
      .eq("annonce_id", annonce.id)
      .eq("acheteur_id", user.id)
      .eq("statut", "acceptee")
      .order("date_proposition", { ascending: false })
      .limit(1)
      .maybeSingle();
    prixNegocie = negoAcceptee?.prix_propose ?? null;
  }

  // Nombre de négociations acceptées (visible seulement par le vendeur)
  let negosAccepteesCount = 0;
  if (user && user.id === annonce.utilisateur_id) {
    const { count } = await supabase
      .from("negociations")
      .select("id", { count: "exact", head: true })
      .eq("annonce_id", annonce.id)
      .eq("statut", "acceptee");
    negosAccepteesCount = count ?? 0;
  }

  // Construire les données
  const imgs = ((annonce.images_annonce ?? []) as { url_image: string; ordre: number }[])
    .sort((a, b) => (a.ordre ?? 0) - (b.ordre ?? 0))
    .map((img) => img.url_image);

  const nomVendeur = vendeurProfil
    ? [vendeurProfil.prenom, vendeurProfil.nom].filter(Boolean).join(" ") || "Vendeur"
    : "Vendeur";

  const seller: SellerInfo = {
    id: annonce.utilisateur_id,
    name: nomVendeur,
    avatar: vendeurProfil?.photo ?? null,
    rating,
    reviewCount: avis.length,
    memberSince: vendeurProfil ? memberSince(vendeurProfil.created_at) : "Inconnu",
    activeListingsCount: (sellerListingsCount ?? 0),
    verified: vendeurProfil != null,
    telephone: vendeurProfil?.telephone ?? null,
  };

  const catNom = (annonce.categories as unknown as { nom: string } | null)?.nom ?? null;

  const similar: Listing[] = similarRaw.map((a) => {
    const simImgs = (a.images_annonce ?? []).sort((x, y) => (x.ordre ?? 0) - (y.ordre ?? 0));
    const simVendeur = simProfilsMap.get(a.utilisateur_id);
    const simNom = simVendeur
      ? [simVendeur.prenom, simVendeur.nom].filter(Boolean).join(" ") || "Vendeur"
      : "Vendeur";
    return {
      id: String(a.id),
      title: a.titre,
      price: a.prix_actuel,
      image: simImgs[0]?.url_image ?? PLACEHOLDER_IMG,
      location: [a.quartier, a.ville].filter(Boolean).join(", ") || "Dakar",
      postedTime: timeAgo(a.date_publication),
      seller: {
        name: simNom,
        avatar: simVendeur?.photo ?? PLACEHOLDER_AVATAR,
        verified: false,
      },
    };
  });

  return { annonce, imgs, seller, catNom, similar, userId: user?.id ?? null, prixNegocie, negosAccepteesCount };
}

// ── page ─────────────────────────────────────────────────────────────────

export default async function AnnonceDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const data = await getAnnonceData(id);

  if (!data) notFound();

  const { annonce, imgs, seller, catNom, similar, userId, prixNegocie, negosAccepteesCount } = data;
  const isNegotiable = annonce.prix_actuel < annonce.prix_initial;
  const location = [annonce.quartier, annonce.ville].filter(Boolean).join(", ") || "Dakar";

  const specs = [
    catNom && { label: "Catégorie", value: catNom },
    { label: "Ville", value: annonce.ville ?? "Dakar" },
    annonce.quartier && { label: "Quartier", value: annonce.quartier },
    isNegotiable && { label: "Prix initial", value: `${annonce.prix_initial.toLocaleString("fr-FR")} FCFA` },
    { label: "Référence", value: `RZ-${annonce.id}` },
    { label: "Publication", value: timeAgo(annonce.date_publication) },
  ].filter(Boolean) as { label: string; value: string }[];

  return (
    <div className="min-h-screen bg-[#FAF9F9] flex flex-col font-[Plus_Jakarta_Sans,sans-serif]">
      <NavbarDecouvrir />

      <main className="flex-1 pb-16">
        <div className="mx-auto max-w-[1280px] px-6 py-6">

          {/* Fil d'ariane */}
          <nav className="mb-6 flex items-center gap-2 text-xs text-[#565E73] flex-wrap">
            <Link href={userId ? "/feed" : "/"} className="hover:text-[#131B2D]">Accueil</Link>
            <ChevronRight className="h-3 w-3 text-gray-400" />
            <Link href="/decouvrir" className="hover:text-[#131B2D]">Annonces</Link>
            {catNom && (
              <>
                <ChevronRight className="h-3 w-3 text-gray-400" />
                <Link href={`/decouvrir?cat=${encodeURIComponent(catNom)}`} className="hover:text-[#131B2D]">
                  {catNom}
                </Link>
              </>
            )}
            <ChevronRight className="h-3 w-3 text-gray-400" />
            <span className="font-semibold text-[#1A1C1C] truncate max-w-xs">{annonce.titre}</span>
          </nav>

          {/* Grille 2 colonnes */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">

            {/* Colonne gauche */}
            <div className="lg:col-span-8 space-y-8">
              <ListingGallery images={imgs} title={annonce.titre} />

              {/* Bandeau prix négocié — visible uniquement par l'acheteur concerné */}
              {prixNegocie !== null && (
                <div className="rounded-2xl border border-[#00966B]/30 bg-[#E8F5EE] px-5 py-4 flex items-center gap-4">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#00966B]">
                    <Check className="h-5 w-5 text-white" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-bold text-[#00966B]">Prix négocié pour vous</p>
                    <p className="text-xl font-extrabold text-[#131B2D]">
                      {prixNegocie.toLocaleString("fr-FR")} FCFA
                    </p>
                    <p className="text-[11px] text-[#565E73]">
                      Économie de {(annonce.prix_actuel - prixNegocie).toLocaleString("fr-FR")} FCFA par rapport au prix affiché.
                    </p>
                  </div>
                </div>
              )}

              {/* Bandeau vendeur — négociations acceptées */}
              {negosAccepteesCount > 0 && userId === annonce.utilisateur_id && (
                <div className="rounded-2xl border border-[#131B2D]/20 bg-[#F4F3F3] px-5 py-3 flex items-center gap-3">
                  <Check className="h-4 w-4 shrink-0 text-[#131B2D]" />
                  <p className="text-xs font-semibold text-[#565E73]">
                    <span className="font-extrabold text-[#131B2D]">{negosAccepteesCount}</span> négociation{negosAccepteesCount > 1 ? "s" : ""} acceptée{negosAccepteesCount > 1 ? "s" : ""} pour cet article.
                  </p>
                </div>
              )}

              {/* Titre & métadonnées */}
              <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.05)]">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-3">
                    <span className="text-2xl md:text-3xl font-black text-[#131B2D]">
                      {prixNegocie !== null
                        ? prixNegocie.toLocaleString("fr-FR")
                        : annonce.prix_actuel.toLocaleString("fr-FR")} FCFA
                    </span>
                    {prixNegocie !== null && (
                      <span className="rounded-full bg-[#E8F5EE] px-3 py-1 text-xs font-bold text-[#00966B]">
                        Prix négocié
                      </span>
                    )}
                    {isNegotiable && prixNegocie === null && (
                      <span className="rounded-full bg-[#E8F5EE] px-3 py-1 text-xs font-bold text-[#00966B]">
                        Négociable
                      </span>
                    )}
                  </div>
                  <span className="text-xs font-mono text-[#76777D]">Réf. RZ-{annonce.id}</span>
                </div>

                <h1 className="mt-3 text-xl md:text-2xl font-extrabold text-[#1A1C1C] leading-snug">
                  {annonce.titre}
                </h1>

                <div className="mt-4 flex flex-wrap items-center gap-4 text-xs text-[#565E73] border-t border-[#F4F3F3] pt-4">
                  <span className="flex items-center gap-1.5 font-medium text-[#1A1C1C]">
                    <MapPin className="h-4 w-4 text-[#FC7138]" />
                    {location}
                  </span>
                  <span>·</span>
                  <span className="flex items-center gap-1.5">
                    <Clock className="h-4 w-4 text-gray-400" />
                    Publié {timeAgo(annonce.date_publication)}
                  </span>
                </div>
              </div>

              {/* Description */}
              {annonce.description && (
                <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.05)]">
                  <div className="flex items-center gap-2 mb-4">
                    <span className="h-4 w-1 rounded-full bg-[#FC7138]" />
                    <h2 className="text-lg font-bold text-[#131B2D]">Description</h2>
                  </div>
                  <p className="text-sm leading-relaxed text-[#1A1C1C]/90 whitespace-pre-wrap">
                    {annonce.description}
                  </p>
                </div>
              )}

              {/* Fiche technique */}
              <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.05)]">
                <div className="flex items-center gap-2 mb-4">
                  <span className="h-4 w-1 rounded-full bg-[#FC7138]" />
                  <h2 className="text-lg font-bold text-[#131B2D]">Caractéristiques</h2>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-0">
                  {specs.map((spec, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between border-b border-[#F4F3F3] py-2.5 text-sm"
                    >
                      <span className="text-[#565E73]">{spec.label}</span>
                      <span className="font-semibold text-[#1A1C1C]">{spec.value}</span>
                    </div>
                  ))}
                </div>

                {/* Réassurance */}
                <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-3 rounded-xl bg-[#FAF9F9] p-4 text-xs font-medium text-[#1A1C1C]">
                  {[
                    "Inspection sur place avant achat",
                    "Rencontre en lieu public sécurisé",
                    "Paiement en espèces ou Wave après remise",
                    "Vérification IMEI / numéro de série possible",
                  ].map((point) => (
                    <div key={point} className="flex items-center gap-2">
                      <Check className="h-4 w-4 text-[#00966B] shrink-0" />
                      <span>{point}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Zone de rencontre */}
              <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.05)]">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="h-4 w-1 rounded-full bg-[#FC7138]" />
                    <h2 className="text-lg font-bold text-[#131B2D]">Zone de rencontre</h2>
                  </div>
                  {annonce.ville && (
                    <span className="text-xs font-semibold text-[#565E73]">{location}</span>
                  )}
                </div>
                <p className="text-xs text-[#76777D] mb-4">
                  Le vendeur privilégie les lieux publics animés (centres commerciaux, cafés) pour la remise.
                </p>
                <div className="relative h-36 w-full overflow-hidden rounded-xl bg-[#E8F1F5] flex items-center justify-center">
                  <div className="text-center p-4">
                    <MapPin className="h-8 w-8 text-[#FC7138] mx-auto animate-bounce" />
                    <p className="mt-2 text-sm font-bold text-[#131B2D]">{location}</p>
                    <p className="text-xs text-[#565E73]">Lieu de remise à confirmer avec le vendeur</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Colonne droite sticky */}
            <div className="lg:col-span-4">
              <SellerStickyCard
                price={annonce.prix_actuel}
                isNegotiable={isNegotiable}
                listingId={String(annonce.id)}
                annonceId={String(annonce.id)}
                titre={annonce.titre}
                prixNegocie={prixNegocie}
                currentUserId={userId}
                seller={seller}
                statut={annonce.statut}
              />
            </div>
          </div>

          {/* Annonces similaires */}
          {similar.length > 0 && (
            <section className="mt-16">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <span className="text-xs font-bold uppercase tracking-wider text-[#FC7138]">
                    Sélection Rizen
                  </span>
                  <h2 className="text-2xl font-black text-[#131B2D]">Vous aimerez aussi</h2>
                </div>
                {catNom && (
                  <Link
                    href={`/decouvrir?cat=${encodeURIComponent(catNom)}`}
                    className="group flex items-center gap-1 text-sm font-bold text-[#FC7138] hover:underline"
                  >
                    Voir tout dans {catNom}
                    <ChevronRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
                  </Link>
                )}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {similar.map((item) => (
                  <ListingCard key={item.id} listing={item} />
                ))}
              </div>
            </section>
          )}

        </div>
      </main>

      {/* Footer minimal */}
      <footer className="w-full bg-[#131B2D] text-white">
        <div className="mx-auto flex max-w-[1280px] flex-col sm:flex-row items-center justify-between gap-4 py-6 px-6 text-xs text-white/60">
          <div className="flex items-center gap-2">
            <span className="font-bold text-white text-base">Rizen</span>
            <span>© 2026 Rizen Marketplace · Dakar, Sénégal</span>
          </div>
          <nav className="flex items-center gap-6">
            <Link href="/cgu" className="hover:text-white transition-colors">CGU</Link>
            <Link href="/confidentialite" className="hover:text-white transition-colors">Confidentialité</Link>
            <Link href="/conseils-securite" className="hover:text-white transition-colors">Conseils sécurité</Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
