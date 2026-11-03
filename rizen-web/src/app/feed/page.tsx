import React from "react";
import Link from "next/link";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { NavbarAuth } from "@/components/layout/NavbarAuth";

export const dynamic = "force-dynamic";
import { ListingCard, Listing } from "@/components/ui/ListingCard";
import { ChevronRight, Sparkles, PlusCircle, ShieldCheck, Users, HelpCircle, Package } from "lucide-react";

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

const PLACEHOLDER_IMG = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";
const PLACEHOLDER_AVATAR = "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop";

// ── fetch ────────────────────────────────────────────────────────────────

async function getFeedData() {
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

  // Profil + catégories favorites en parallèle
  const [profilRes, categoriesRes, favorisRes] = await Promise.all([
    user
      ? supabase.from("profils").select("prenom, photo").eq("id", user.id).maybeSingle()
      : Promise.resolve({ data: null }),
    supabase.from("categories").select("id, nom").order("id").limit(8),
    user
      ? supabase
          .from("favoris")
          .select("annonces(categorie_id)")
          .eq("utilisateur_id", user.id)
          .limit(30)
      : Promise.resolve({ data: [] }),
  ]);

  const profil = profilRes.data ?? null;
  const rawCategories = categoriesRes.data;

  // Catégories préférées de l'utilisateur (basé sur ses favoris)
  const favCatIds = Array.from(
    new Set(
      ((favorisRes.data ?? []) as unknown as { annonces: { categorie_id: number | null } | null }[])
        .map((f) => f.annonces?.categorie_id)
        .filter((id): id is number => id !== null && id !== undefined)
    )
  );

  type RawAnnonce = {
    id: number; titre: string; prix_actuel: number;
    ville: string | null; quartier: string | null;
    date_publication: string; utilisateur_id: string;
    images_annonce?: { url_image: string; ordre: number }[];
  };

  // Annonces personnalisées : catégories favorites d'abord, puis les autres récentes
  let rawAnnonces: RawAnnonce[] | null = null;
  if (favCatIds.length > 0) {
    const [favRes, otherRes] = await Promise.all([
      supabase
        .from("annonces")
        .select("id, titre, prix_actuel, ville, quartier, date_publication, utilisateur_id, images_annonce(url_image, ordre)")
        .eq("statut", "active")
        .in("categorie_id", favCatIds)
        .order("date_publication", { ascending: false })
        .limit(8),
      supabase
        .from("annonces")
        .select("id, titre, prix_actuel, ville, quartier, date_publication, utilisateur_id, images_annonce(url_image, ordre)")
        .eq("statut", "active")
        .not("categorie_id", "in", `(${favCatIds.join(",")})`)
        .order("date_publication", { ascending: false })
        .limit(8),
    ]);
    const favItems = favRes.data ?? [];
    const otherItems = otherRes.data ?? [];
    // Dédupliquer par id
    const seen = new Set(favItems.map((a) => a.id));
    rawAnnonces = [...favItems, ...otherItems.filter((a) => !seen.has(a.id))].slice(0, 12);
  } else {
    const { data } = await supabase
      .from("annonces")
      .select("id, titre, prix_actuel, ville, quartier, date_publication, utilisateur_id, images_annonce(url_image, ordre)")
      .eq("statut", "active")
      .order("date_publication", { ascending: false })
      .limit(12);
    rawAnnonces = data;
  }

  // Profils vendeurs
  const annonces: RawAnnonce[] = rawAnnonces ?? [];
  const uids = Array.from(new Set(annonces.map((a) => a.utilisateur_id)));
  const { data: rawProfils } = uids.length
    ? await supabase.from("profils").select("id, prenom, nom, photo").in("id", uids)
    : { data: [] };

  const profilsMap = new Map(
    (rawProfils ?? []).map((p: { id: string; prenom: string | null; nom: string | null; photo: string | null }) => [p.id, p])
  );

  // Mapper vers Listing
  const listings: Listing[] = annonces.map((a) => {
    const imgs = (a.images_annonce ?? []).sort((x, y) => (x.ordre ?? 0) - (y.ordre ?? 0));
    const vendeur = profilsMap.get(a.utilisateur_id);
    const nomVendeur = vendeur
      ? [vendeur.prenom, vendeur.nom].filter(Boolean).join(" ") || "Vendeur"
      : "Vendeur";
    return {
      id: String(a.id),
      title: a.titre,
      price: a.prix_actuel,
      image: imgs[0]?.url_image ?? PLACEHOLDER_IMG,
      location: [a.quartier, a.ville].filter(Boolean).join(", ") || "Dakar",
      postedTime: timeAgo(a.date_publication),
      seller: {
        name: nomVendeur,
        avatar: vendeur?.photo ?? PLACEHOLDER_AVATAR,
        verified: false,
      },
    };
  });

  const categories = (rawCategories ?? []).map((c: { id: number; nom: string }) => c.nom);

  return { profil, listings, categories, isPersonalized: favCatIds.length > 0 };
}

// ── page ─────────────────────────────────────────────────────────────────

export default async function FeedPage() {
  const { profil, listings, categories, isPersonalized } = await getFeedData();

  const recent = listings.slice(0, 4);
  const newer = listings.slice(4, 8);
  const all = listings.slice(0, 8);
  const greeting = profil?.prenom ? `Bonjour ${profil.prenom}` : "Bonjour";

  return (
    <div className="min-h-screen bg-[#FAF9F9] flex flex-col font-[Plus_Jakarta_Sans,sans-serif]">
      <NavbarAuth prenom={profil?.prenom} photo={profil?.photo} />

      <main className="flex-1 pb-16">
        {/* Hero */}
        <section className="relative bg-[#131B2D] py-12 overflow-hidden">
          <div
            className="pointer-events-none absolute inset-0"
            style={{
              background: "radial-gradient(circle at 80% 40%, rgba(252,113,56,0.18), transparent 55%)",
            }}
          />
          <div className="mx-auto max-w-[1280px] px-6 text-center relative z-10">
            <h1 className="text-3xl md:text-4xl font-extrabold tracking-tight text-white">
              {greeting} — Que cherchez-vous aujourd&apos;hui ?
            </h1>
            <p className="mt-2 text-sm text-white/70 max-w-xl mx-auto">
              Explorez les meilleures offres sécurisées entre particuliers et commerçants à Dakar.
            </p>

            <div className="mt-6 flex justify-center">
              <div className="relative w-full max-w-[600px]">
                <input
                  type="text"
                  placeholder="Rechercher un véhicule, un bien, un smartphone..."
                  className="h-[52px] w-full rounded-full bg-white pl-6 pr-32 text-sm text-[#1A1C1C] shadow-lg placeholder-[#76777D] outline-none transition-all focus:ring-2 focus:ring-[#FC7138]"
                />
                <button
                  type="button"
                  className="absolute right-1.5 top-1/2 -translate-y-1/2 rounded-full bg-[#FC7138] px-6 py-2.5 text-sm font-bold text-white shadow-md hover:bg-[#e05f29] transition-all"
                >
                  Explorer
                </button>
              </div>
            </div>

            {categories.length > 0 && (
              <div className="mt-6 flex flex-wrap items-center justify-center gap-2.5">
                {categories.map((cat) => (
                  <Link
                    key={cat}
                    href={`/decouvrir?cat=${encodeURIComponent(cat)}`}
                    className="rounded-full bg-white/10 px-4 py-1.5 text-xs font-semibold text-white/90 backdrop-blur-md hover:bg-white/20 transition-all"
                  >
                    {cat}
                  </Link>
                ))}
              </div>
            )}
          </div>
        </section>

        <div className="mx-auto max-w-[1280px] px-6 mt-10 space-y-12">
          {/* Section : Annonces récentes */}
          {recent.length > 0 && (
            <section>
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-2">
                  <span className="h-4 w-1 rounded-full bg-[#FC7138]" />
                  <h2 className="text-xl font-bold text-[#131B2D]">
                    {isPersonalized ? "Sélectionné pour vous" : "Près de chez vous · Dakar"}
                  </h2>
                </div>
                <Link
                  href="/decouvrir"
                  className="group flex items-center gap-1 text-sm font-bold text-[#FC7138] hover:underline"
                >
                  Voir tout
                  <ChevronRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
                </Link>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {recent.map((item) => (
                  <ListingCard key={item.id} listing={item} />
                ))}
              </div>
            </section>
          )}

          {/* Bannière promo */}
          <section className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#FC7138] to-[#ff8c5d] p-8 text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)]">
            <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
              <div className="max-w-xl">
                <span className="inline-flex items-center gap-1.5 rounded-full bg-white/20 px-3 py-1 text-xs font-semibold text-white mb-2">
                  <Sparkles className="h-3.5 w-3.5" />
                  Dépôt gratuit & instantané
                </span>
                <h3 className="text-2xl font-black tracking-tight text-white">
                  Vendez ce dont vous n&apos;avez plus besoin en quelques clics
                </h3>
                <p className="mt-1.5 text-sm text-white/90">
                  Touchez des milliers d&apos;acheteurs vérifiés à Dakar et partout au Sénégal.
                </p>
              </div>
              <Link
                href="/annonces/creer"
                className="flex items-center gap-2 rounded-full bg-white px-7 py-3 text-sm font-bold text-[#FC7138] shadow-md hover:bg-[#FAF9F9] transition-transform active:scale-95 shrink-0"
              >
                <PlusCircle className="h-4 w-4" />
                Publier une annonce
              </Link>
            </div>
          </section>

          {/* Section : Nouvelles annonces */}
          {newer.length > 0 && (
            <section>
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-2">
                  <span className="h-4 w-1 rounded-full bg-[#00966B]" />
                  <h2 className="text-xl font-bold text-[#131B2D]">Nouvelles annonces</h2>
                </div>
                <Link
                  href="/decouvrir"
                  className="group flex items-center gap-1 text-sm font-bold text-[#FC7138] hover:underline"
                >
                  Voir tout
                  <ChevronRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
                </Link>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {newer.map((item) => (
                  <ListingCard key={item.id} listing={item} />
                ))}
              </div>
            </section>
          )}

          {/* Section : Toutes les annonces */}
          {all.length > 0 && (
            <section>
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-2">
                  <span className="h-4 w-1 rounded-full bg-[#131B2D]" />
                  <h2 className="text-xl font-bold text-[#131B2D]">Toutes les annonces</h2>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {all.map((item, idx) => (
                  <ListingCard key={`all-${item.id}-${idx}`} listing={item} />
                ))}
              </div>

              <div className="mt-10 flex flex-col items-center justify-center">
                <Link
                  href="/decouvrir"
                  className="flex items-center gap-2 rounded-full border border-[#131B2D] bg-white px-8 py-3 text-sm font-bold text-[#131B2D] shadow-sm hover:bg-[#F4F3F3] active:scale-95 transition-all"
                >
                  Voir toutes les annonces
                  <ChevronRight className="h-4 w-4" />
                </Link>
              </div>
            </section>
          )}

          {/* Empty state */}
          {listings.length === 0 && (
            <section className="py-20 flex flex-col items-center text-center">
              <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-[#F4F3F3]">
                <Package className="h-8 w-8 text-[#565E73]" />
              </div>
              <h2 className="text-xl font-bold text-[#131B2D]">Aucune annonce pour le moment</h2>
              <p className="text-sm text-[#565E73] mt-2 mb-6">Soyez le premier à publier une annonce sur Rizen.</p>
              <Link
                href="/annonces/creer"
                className="rounded-full bg-[#FC7138] px-7 py-3 text-sm font-semibold text-white shadow-md hover:bg-[#e05f29] transition-all"
              >
                Publier une annonce
              </Link>
            </section>
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full bg-[#131B2D] text-white mt-16">
        <div className="border-b border-white/10 py-8">
          <div className="mx-auto grid max-w-[1280px] grid-cols-1 md:grid-cols-3 gap-6 px-6">
            <div className="flex items-center gap-3.5">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/10 text-[#00966B]">
                <ShieldCheck className="h-6 w-6" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Profils Vérifiés</h4>
                <p className="text-xs text-white/70">Contrôle d&apos;identité strict pour chaque vendeur</p>
              </div>
            </div>
            <div className="flex items-center gap-3.5">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/10 text-[#FC7138]">
                <Users className="h-6 w-6" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Esprit Teranga</h4>
                <p className="text-xs text-white/70">Rencontres sécurisées et remises en main propre</p>
              </div>
            </div>
            <div className="flex items-center gap-3.5">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/10 text-white/90">
                <HelpCircle className="h-6 w-6" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Assistance Locale</h4>
                <p className="text-xs text-white/70">Équipe disponible 7j/7 basée à Dakar</p>
              </div>
            </div>
          </div>
        </div>

        <div className="mx-auto flex max-w-[1280px] flex-col sm:flex-row items-center justify-between gap-4 py-6 px-6 text-xs text-white/60">
          <div className="flex items-center gap-2">
            <span className="font-bold text-white text-base">Rizen</span>
            <span>© 2026 Rizen Marketplace · Dakar, Sénégal</span>
          </div>
          <nav className="flex items-center gap-6">
            <Link href="/cgu" className="hover:text-white transition-colors">CGU</Link>
            <Link href="/confidentialite" className="hover:text-white transition-colors">Confidentialité</Link>
            <Link href="/regles" className="hover:text-white transition-colors">Règles</Link>
            <Link href="/conseils-securite" className="hover:text-white transition-colors">Conseils sécurité</Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
