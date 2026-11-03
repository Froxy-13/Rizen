export const dynamic = "force-dynamic";

import React from "react";
import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { NavbarAuth } from "@/components/layout/NavbarAuth";
import { ProfilTabsClient, MainTab } from "./ProfilTabsClient";
import { ManagedListing } from "@/components/ui/ManageListingCard";
import { Edit3, Settings, CheckCircle2, Star, Tag, MapPin } from "lucide-react";

// ── helpers ──────────────────────────────────────────────────────────────────

function memberSince(date: string): string {
  return new Date(date).toLocaleDateString("fr-FR", { month: "long", year: "numeric" });
}

const PLACEHOLDER_IMG = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

// ── fetch ─────────────────────────────────────────────────────────────────────

async function getProfilData() {
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

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/auth/gate?redirect=/profil");

  const [
    { data: profil },
    { data: rawAnnonces },
    { data: rawAvis },
    { data: rawFavoris },
    { data: transactionsRaw },
  ] = await Promise.all([
    supabase.from("profils").select("*").eq("id", user.id).maybeSingle(),

    supabase
      .from("annonces")
      .select("id, titre, prix_actuel, ville, quartier, statut, images_annonce(url_image, ordre), categories(nom)")
      .eq("utilisateur_id", user.id)
      .order("date_publication", { ascending: false }),

    supabase
      .from("avis")
      .select("note, commentaire, date_avis, profils:acheteur_id(nom, prenom, photo)")
      .eq("vendeur_id", user.id)
      .eq("emetteur", "acheteur")
      .order("date_avis", { ascending: false }),

    supabase
      .from("favoris")
      .select(`
        id,
        date_ajout,
        annonces (
          id, titre, prix_actuel, prix_initial, ville, quartier, date_publication,
          images_annonce ( url_image, ordre ),
          profils:utilisateur_id ( nom, prenom, photo, certifie ),
          categories ( nom )
        )
      `)
      .eq("utilisateur_id", user.id)
      .order("date_ajout", { ascending: false }),

    supabase
      .from("transactions")
      .select(`
        id, statut, montant, created_at, updated_at, acheteur_id, vendeur_id,
        annonces!annonce_id ( id, titre, images_annonce ( url_image, ordre ) ),
        acheteur:profils!acheteur_id ( nom, prenom, photo ),
        vendeur:profils!vendeur_id ( nom, prenom, photo )
      `)
      .or(`acheteur_id.eq.${user.id},vendeur_id.eq.${user.id}`)
      .order("created_at", { ascending: false }),
  ]);

  // ── Annonces ─────────────────────────────────────────────────────────────
  const annonces = rawAnnonces ?? [];

  const toManaged = (a: {
    id: number;
    titre: string;
    prix_actuel: number;
    ville: string | null;
    quartier: string | null;
    statut: string;
    images_annonce?: { url_image: string; ordre: number }[];
    categories?: unknown;
  }): ManagedListing => {
    const imgs = (a.images_annonce ?? []).sort((x, y) => (x.ordre ?? 0) - (y.ordre ?? 0));
    const catNom = (a.categories as unknown as { nom: string } | null)?.nom ?? "Autre";
    return {
      id: String(a.id),
      title: a.titre,
      category: catNom,
      price: a.prix_actuel,
      location: [a.quartier, a.ville].filter(Boolean).join(", ") || "Dakar",
      image: imgs[0]?.url_image ?? PLACEHOLDER_IMG,
      status: (a.statut as ManagedListing["status"]) ?? "active",
    };
  };

  const activeListings    = annonces.filter((a: { statut: string }) => a.statut === "active").map(toManaged);
  const suspendedListings = annonces.filter((a: { statut: string }) => a.statut === "suspendue").map(toManaged);
  const soldListings      = annonces.filter((a: { statut: string }) => a.statut === "vendue").map(toManaged);

  // ── Avis ─────────────────────────────────────────────────────────────────
  type AvisRaw = {
    note: number;
    commentaire: string | null;
    date_avis: string;
    profils: { nom: string; prenom: string | null; photo: string | null } | null;
  };

  const avisItems = ((rawAvis ?? []) as unknown as AvisRaw[]).map((a) => ({
    note: a.note,
    commentaire: a.commentaire,
    date_avis: a.date_avis,
    acheteur: a.profils,
  }));

  const noteMoyenne = avisItems.length > 0
    ? Math.round((avisItems.reduce((s, a) => s + (a.note ?? 0), 0) / avisItems.length) * 10) / 10
    : null;

  // ── Favoris ──────────────────────────────────────────────────────────────
  type RawFavori = {
    id: number;
    date_ajout: string;
    annonces: {
      id: number;
      titre: string;
      prix_actuel: number;
      prix_initial: number;
      ville: string | null;
      quartier: string | null;
      date_publication: string;
      images_annonce: { url_image: string; ordre: number }[];
      profils: { nom: string; prenom: string | null; photo: string | null; certifie?: boolean } | null;
      categories: { nom: string } | null;
    } | null;
  };

  const favoriItems = ((rawFavoris ?? []) as unknown as RawFavori[])
    .filter((f) => f.annonces !== null)
    .map((f) => {
      const a = f.annonces!;
      const imgs = (a.images_annonce ?? []).sort((x, y) => (x.ordre ?? 0) - (y.ordre ?? 0));
      return {
        favoriId: f.id,
        dateAjout: f.date_ajout,
        annonce: {
          id: a.id,
          titre: a.titre,
          prix_actuel: a.prix_actuel,
          prix_initial: a.prix_initial,
          ville: a.ville,
          quartier: a.quartier,
          date_publication: a.date_publication,
          imageUrl: imgs[0]?.url_image ?? PLACEHOLDER_IMG,
          categorieNom: a.categories?.nom ?? null,
          vendeur: a.profils,
        },
      };
    });

  // ── Transactions ─────────────────────────────────────────────────────────
  type TxRaw = {
    id: number;
    statut: string;
    montant: number | null;
    created_at: string;
    updated_at: string;
    acheteur_id: string;
    vendeur_id: string;
    annonces: { id: number; titre: string; images_annonce: { url_image: string; ordre: number }[] } | null;
    acheteur: { nom: string; prenom: string | null; photo: string | null } | null;
    vendeur: { nom: string; prenom: string | null; photo: string | null } | null;
  };

  const rawTx = (transactionsRaw ?? []) as unknown as TxRaw[];

  const transactionItems = rawTx.map((tx) => {
    const role: "acheteur" | "vendeur" = tx.acheteur_id === user.id ? "acheteur" : "vendeur";
    const otherParty = role === "acheteur" ? tx.vendeur : tx.acheteur;
    const imgs = (tx.annonces?.images_annonce ?? []).sort((a, b) => (a.ordre ?? 0) - (b.ordre ?? 0));
    return {
      id: tx.id,
      statut: tx.statut,
      montant: tx.montant,
      created_at: tx.created_at,
      role,
      annonce: tx.annonces
        ? { id: tx.annonces.id, titre: tx.annonces.titre, imageUrl: imgs[0]?.url_image ?? null }
        : null,
      otherParty,
    };
  });

  const transactionsVendues = rawTx.filter(
    (tx) => tx.vendeur_id === user.id && tx.statut === "completee"
  ).length;

  return {
    user,
    profil,
    noteMoyenne,
    avisCount: avisItems.length,
    activeCount: activeListings.length,
    transactionsVendues,
    favorisCount: favoriItems.length,
    activeListings,
    suspendedListings,
    soldListings,
    favoriItems,
    avisItems,
    transactionItems,
  };
}

// ── page ──────────────────────────────────────────────────────────────────────

const VALID_TABS: MainTab[] = ["annonces", "favoris", "avis", "transactions"];

export default async function ProfilPage({
  searchParams,
}: {
  searchParams: Promise<{ tab?: string }>;
}) {
  const { tab: tabParam } = await searchParams;
  const initialTab: MainTab = VALID_TABS.includes(tabParam as MainTab)
    ? (tabParam as MainTab)
    : "annonces";

  const {
    profil,
    noteMoyenne,
    avisCount,
    activeCount,
    transactionsVendues,
    favorisCount,
    activeListings,
    suspendedListings,
    soldListings,
    favoriItems,
    avisItems,
    transactionItems,
  } = await getProfilData();

  const prenom = profil?.prenom ?? "Utilisateur";
  const nom = profil?.nom ?? "";
  const fullName = [prenom, nom].filter(Boolean).join(" ");
  const initiale = prenom[0]?.toUpperCase() ?? "?";
  const location = (profil as unknown as { ville?: string })?.ville ?? profil?.adresse ?? "Dakar";

  return (
    <div className="min-h-screen bg-[#FAF9F9] flex flex-col font-[Plus_Jakarta_Sans,sans-serif]">
      <NavbarAuth prenom={profil?.prenom} photo={profil?.photo} />

      <main className="flex-1 pb-16">
        <div className="mx-auto max-w-[1280px] px-6 py-6 space-y-8">

          {/* ── Hero profil ─────────────────────────────────────── */}
          <section className="relative overflow-hidden rounded-3xl bg-[#131B2D] p-8 md:p-10 text-white shadow-[0_8px_30px_rgba(19,27,45,0.12)]">
            <div
              className="pointer-events-none absolute -right-24 -top-24 h-96 w-96 rounded-full opacity-20 blur-3xl"
              style={{ background: "#FC7138" }}
            />

            <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
              {/* Identité */}
              <div className="flex items-center gap-6">
                <div className="relative h-24 w-24 shrink-0 rounded-full ring-4 ring-white/90 overflow-hidden shadow-lg bg-[#FFDBBF] flex items-center justify-center">
                  {profil?.photo ? (
                    <Image src={profil.photo} alt={fullName} fill className="object-cover" />
                  ) : (
                    <span className="text-[#FC7138] text-3xl font-black">{initiale}</span>
                  )}
                  <span className="absolute bottom-1 right-1 h-5 w-5 rounded-full border-2 border-[#131B2D] bg-[#00966B]" />
                </div>

                <div>
                  <div className="flex flex-wrap items-center gap-3">
                    <h1 className="text-2xl md:text-3xl font-extrabold tracking-tight text-white">
                      {fullName}
                    </h1>
                    {(profil as unknown as { certifie?: boolean })?.certifie && (
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-[#00966B]/20 border border-[#00966B]/40 px-3 py-1 text-xs font-bold text-[#44e1ad]">
                        <CheckCircle2 className="h-3.5 w-3.5 fill-[#00966B] text-white" />
                        Vendeur Certifié Dakar
                      </span>
                    )}
                  </div>

                  <div className="mt-2 flex flex-wrap items-center gap-y-1 gap-x-4 text-xs text-white/80">
                    {noteMoyenne !== null && (
                      <>
                        <span className="flex items-center gap-1 font-semibold text-white">
                          <Star className="h-3.5 w-3.5 fill-[#FC7138] text-[#FC7138]" />
                          {noteMoyenne.toFixed(1)} / 5.0
                          <span className="font-normal text-white/60">({avisCount} avis)</span>
                        </span>
                        <span>·</span>
                      </>
                    )}
                    <span className="flex items-center gap-1">
                      <MapPin className="h-3.5 w-3.5 text-white/60" />
                      {location}
                    </span>
                    {profil?.created_at && (
                      <>
                        <span>·</span>
                        <span className="text-white/60">Membre depuis {memberSince(profil.created_at)}</span>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-3">
                <Link
                  href="/profil/modifier"
                  className="flex items-center gap-2 rounded-full bg-white/10 hover:bg-white/20 border border-white/20 px-5 py-2.5 text-xs font-bold text-white backdrop-blur-md transition-all active:scale-95"
                >
                  <Edit3 className="h-3.5 w-3.5" />
                  Modifier mon profil
                </Link>
                <Link
                  href="/parametres"
                  aria-label="Paramètres"
                  className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 hover:bg-white/20 border border-white/20 text-white transition-all"
                >
                  <Settings className="h-4 w-4" />
                </Link>
              </div>
            </div>

            {/* Métriques */}
            <div className="relative z-10 mt-8 grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="flex items-center justify-between rounded-2xl bg-white p-5 text-[#131B2D] shadow-sm">
                <div>
                  <div className="text-3xl font-black tracking-tight">{activeCount}</div>
                  <div className="text-xs font-semibold text-[#565E73] mt-0.5">Annonces actives</div>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#FFF7F4] text-[#FC7138]">
                  <Tag className="h-6 w-6" />
                </div>
              </div>

              <div className="flex items-center justify-between rounded-2xl bg-white p-5 text-[#131B2D] shadow-sm">
                <div>
                  <div className="text-3xl font-black tracking-tight">{transactionsVendues}</div>
                  <div className="text-xs font-semibold text-[#565E73] mt-0.5">Ventes conclues</div>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#E8F5EE] text-[#00966B]">
                  <CheckCircle2 className="h-6 w-6" />
                </div>
              </div>

              <div className="flex items-center justify-between rounded-2xl bg-white p-5 text-[#131B2D] shadow-sm">
                <div>
                  {noteMoyenne !== null ? (
                    <div className="flex items-center gap-1.5 text-3xl font-black tracking-tight">
                      {noteMoyenne.toFixed(1)}
                      <Star className="h-5 w-5 fill-[#FC7138] text-[#FC7138]" />
                    </div>
                  ) : (
                    <div className="text-3xl font-black tracking-tight text-[#76777D]">—</div>
                  )}
                  <div className="text-xs font-semibold text-[#565E73] mt-0.5">
                    Note moyenne {avisCount > 0 ? `(${avisCount} avis)` : ""}
                  </div>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#FFF7F4] text-[#FC7138]">
                  <Star className="h-6 w-6" />
                </div>
              </div>
            </div>
          </section>

          {/* ── Onglets ─────────────────────────────────────────── */}
          <ProfilTabsClient
            activeListings={activeListings}
            suspendedListings={suspendedListings}
            soldListings={soldListings}
            favoriItems={favoriItems}
            avisItems={avisItems}
            transactionItems={transactionItems}
            counts={{ annonces: activeCount, favoris: favorisCount, avis: avisCount, transactions: transactionItems.length }}
            initialTab={initialTab}
          />

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
