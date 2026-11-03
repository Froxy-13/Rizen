import Image from "next/image";
import Link from "next/link";
import {
  fetchCategories,
  fetchRecentAnnonces,
  fetchTopSellers,
  fetchStats,
  type DBCategorie,
  type DBAnnonceWithDetails,
  type DBTopSeller,
} from "@/lib/supabase-server";

// ─── Helpers ─────────────────────────────────────────────────────────

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const m = Math.floor(diff / 60000);
  const h = Math.floor(diff / 3600000);
  const d = Math.floor(diff / 86400000);
  if (m < 2) return "À l'instant";
  if (m < 60) return `Il y a ${m}min`;
  if (h < 24) return `Il y a ${h}h`;
  if (d === 1) return "Hier";
  if (d < 7) return `Il y a ${d}j`;
  return `Il y a ${Math.floor(d / 7)}sem`;
}

function formatFCFA(n: number): string {
  return new Intl.NumberFormat("fr-FR").format(n) + " FCFA";
}

function formatStat(n: number): string {
  if (n === 0) return "–";
  return new Intl.NumberFormat("fr-FR").format(n) + "+";
}

function formatLocation(ville: string | null, quartier: string | null): string {
  if (quartier && ville) return `${quartier}, ${ville}`;
  return ville ?? quartier ?? "Sénégal";
}

const ICON_MAP: Record<string, string> = {
  "électronique": "smartphone", "electronique": "smartphone",
  "vêtements": "apparel", "vetements": "apparel",
  "maison": "chair",
  "véhicules": "two_wheeler", "vehicules": "two_wheeler",
  "livres": "menu_book",
  "sport": "fitness_center",
  "beauté": "spa", "beaute": "spa",
};

function categoryIcon(cat: DBCategorie): string {
  return ICON_MAP[cat.nom.toLowerCase()] || "grid_view";
}

function sellerInitials(s: { prenom: string | null; nom: string | null }): string {
  return `${s.prenom?.[0] ?? ""}${s.nom?.[0] ?? ""}`.toUpperCase() || "?";
}

// ─── Fallback data (si Supabase est vide) ───────────────────────────

const FALLBACK_CATEGORIES: DBCategorie[] = [
  { id: 1, nom: "Électronique" },
  { id: 2, nom: "Vêtements" },
  { id: 3, nom: "Maison" },
  { id: 4, nom: "Véhicules" },
  { id: 5, nom: "Livres" },
  { id: 6, nom: "Sport" },
  { id: 7, nom: "Beauté" },
  { id: 8, nom: "Autres" },
];

// ─── Page (Server Component) ────────────────────────────────────────

export default async function HomePage() {
  const [categoriesRaw, annonces, sellers, stats] = await Promise.all([
    fetchCategories(),
    fetchRecentAnnonces(),
    fetchTopSellers(),
    fetchStats(),
  ]);

  const categories = categoriesRaw.length ? categoriesRaw : FALLBACK_CATEGORIES;

  return (
    <div className="min-h-screen bg-surface font-sans text-on-surface antialiased">

      {/* ══════════════════════ NAVBAR ══════════════════════ */}
      <header className="fixed top-0 left-0 right-0 z-50 bg-on-secondary-fixed shadow-[0_4px_20px_rgba(19,27,45,0.08)]">
        <div className="h-20 max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop flex items-center justify-between gap-gutter">
          <div className="flex items-center gap-space-lg">
            <Link href="/" className="flex items-center group">
              <Image
                src="/Rizen.png"
                alt="Rizen"
                width={100}
                height={32}
                className="h-8 w-auto object-contain"
                priority
              />
            </Link>
            <nav className="hidden md:flex items-center gap-space-lg">
              <Link href="/" className="font-label-lg text-label-lg text-on-secondary font-bold">Accueil</Link>
              <Link href="/decouvrir" className="font-label-lg text-label-lg text-secondary-fixed-dim hover:text-on-secondary transition-colors">Découvrir</Link>
              <a href="#comment-ca-marche" className="font-label-lg text-label-lg text-secondary-fixed-dim hover:text-on-secondary transition-colors">Comment ça marche</a>
            </nav>
          </div>
          <div className="flex items-center gap-2 sm:gap-space-md">
            <Link
              href="/auth/login"
              className="inline-flex items-center justify-center px-3 sm:px-space-md py-space-sm rounded-full font-label-lg text-label-lg text-on-secondary hover:bg-secondary-container/20 transition-all text-sm"
            >
              Se connecter
            </Link>
            <Link
              href="/auth/register"
              className="inline-flex items-center justify-center px-3 sm:px-space-lg py-space-sm h-[40px] sm:h-[44px] rounded-full bg-primary-container text-white font-label-lg text-label-lg shadow-[0_8px_24px_rgba(252,113,56,0.25)] hover:bg-[#e45f28] transition-all active:scale-95 text-sm"
            >
              <span className="sm:hidden">S&apos;inscrire</span>
              <span className="hidden sm:inline">Publier une annonce</span>
            </Link>
          </div>
        </div>
      </header>

      <main className="w-full pt-20">

        {/* ══════════════════════ HERO ══════════════════════ */}
        <section className="relative w-full overflow-hidden bg-gradient-to-br from-[#FFF4EF] via-surface-container-low to-background pt-space-xl pb-space-xl md:py-24">
          <div className="absolute -top-24 right-1/4 w-96 h-96 rounded-full bg-primary-fixed/40 blur-3xl pointer-events-none" />
          <div className="absolute top-1/2 -left-20 w-80 h-80 rounded-full bg-tertiary-fixed/20 blur-3xl pointer-events-none" />

          <div className="max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop relative z-10">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">

              {/* ── Colonne gauche ── */}
              <div className="lg:col-span-7 flex flex-col items-start space-y-space-lg">
                <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-surface-container-lowest shadow-[0_4px_20px_rgba(19,27,45,0.06)] text-primary-container font-label-md text-label-md">
                  <span>🇸🇳</span>
                  <span className="font-bold tracking-tight">Marketplace sénégalais</span>
                </div>

                <h1 className="text-on-secondary-fixed font-bold tracking-tight text-[42px] leading-[48px] md:text-[56px] md:leading-[62px]">
                  Achetez et vendez <br className="hidden sm:inline" />
                  <span className="text-primary-container">d&apos;occasion</span>, facilement.
                </h1>

                <p className="font-body-lg text-body-lg text-secondary max-w-xl leading-relaxed">
                  Trouvez des articles de seconde main vérifiés près de chez vous. Négociez directement,
                  payez en toute sécurité avec Wave ou Orange Money, et embrassez la Teranga digitale.
                </p>

                <div className="flex flex-col sm:flex-row sm:flex-wrap items-stretch sm:items-center gap-3 pt-2 w-full sm:w-auto">
                  <Link
                    href="/decouvrir"
                    className="h-[52px] px-8 rounded-full bg-primary-container text-white font-label-lg text-label-lg inline-flex items-center justify-center gap-2 shadow-[0_8px_24px_rgba(252,113,56,0.28)] hover:bg-[#e45f28] transition-all transform hover:-translate-y-0.5"
                  >
                    <span>Parcourir les annonces</span>
                    <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
                  </Link>
                  <Link
                    href="/auth/register"
                    className="h-[52px] px-8 rounded-full bg-surface-container-lowest text-on-secondary-fixed font-label-lg text-label-lg inline-flex items-center justify-center gap-2 shadow-[0_4px_20px_rgba(19,27,45,0.06)] hover:bg-secondary-fixed/30 transition-all"
                  >
                    <span className="material-symbols-outlined text-primary-container text-[20px]">add_circle</span>
                    <span>Vendre un article</span>
                  </Link>
                </div>

                <div className="pt-6 w-full">
                  <div className="flex flex-wrap items-center gap-y-3 gap-x-6 text-secondary font-label-md text-label-md bg-surface-container-lowest/80 backdrop-blur px-6 py-3.5 rounded-2xl shadow-[0_4px_20px_rgba(19,27,45,0.04)]">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-primary-container" />
                      <span className="font-bold text-on-secondary-fixed">{formatStat(stats.annonces_actives)}</span> annonces actives
                    </div>
                    <span className="text-outline-variant hidden sm:inline">•</span>
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-tertiary" />
                      <span className="font-bold text-on-secondary-fixed">{formatStat(stats.vendeurs_actifs)}</span> vendeurs certifiés
                    </div>
                    <span className="text-outline-variant hidden sm:inline">•</span>
                    <div className="flex items-center gap-2">
                      <span className="material-symbols-outlined text-tertiary text-[18px]">verified_user</span>
                      <span className="font-bold text-on-secondary-fixed">Paiement sécurisé</span> garanti
                    </div>
                  </div>
                </div>
              </div>

              {/* ── Colonne droite : Mockup ── */}
              <div className="lg:col-span-5 relative flex justify-center items-center py-6">
                <div className="absolute w-[360px] h-[360px] md:w-[440px] md:h-[440px] rounded-full bg-[#FFDBBF]/60 blur-2xl transform -translate-x-4" />
                <div className="absolute w-[260px] h-[260px] rounded-full bg-primary-container/15 blur-xl transform translate-x-12 translate-y-12" />

                {/* Phone frame */}
                <div className="relative z-10 w-[290px] sm:w-[320px] bg-on-secondary-fixed rounded-[42px] p-3.5 shadow-[0_25px_60px_rgba(19,27,45,0.22)] transform rotate-[-4deg] md:rotate-[6deg] hover:rotate-0 transition-transform duration-500 ease-out">
                  <div className="relative bg-surface rounded-[34px] overflow-hidden flex flex-col h-[540px]">
                    {/* Status bar */}
                    <div className="w-full bg-surface pt-3 px-6 pb-2 flex justify-between items-center text-xs font-bold text-on-secondary-fixed">
                      <span>09:41</span>
                      <div className="w-16 h-4 bg-on-secondary-fixed rounded-full mx-auto" />
                      <div className="flex items-center gap-1">
                        <span className="material-symbols-outlined text-[14px]">signal_cellular_4_bar</span>
                        <span className="material-symbols-outlined text-[14px]">battery_full</span>
                      </div>
                    </div>
                    {/* In-app header */}
                    <div className="px-4 py-2 bg-surface flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-primary-container/20 flex items-center justify-center text-primary-container font-bold text-xs">R</div>
                        <div>
                          <p className="font-label-sm text-label-sm text-secondary">Localisation</p>
                          <p className="font-label-md text-label-md text-on-secondary-fixed flex items-center gap-0.5">
                            Dakar, Almadies <span className="material-symbols-outlined text-[14px]">expand_more</span>
                          </p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-secondary text-[22px]">notifications</span>
                    </div>
                    {/* Search bar */}
                    <div className="px-4 py-2">
                      <div className="w-full h-9 bg-surface-container-lowest rounded-full px-3 flex items-center gap-2 shadow-[0_2px_8px_rgba(19,27,45,0.04)] text-secondary text-xs">
                        <span className="material-symbols-outlined text-[16px]">search</span>
                        <span>Que cherchez-vous à Dakar ?</span>
                      </div>
                    </div>
                    {/* Mini cards */}
                    <div className="flex-1 p-3 space-y-3 overflow-hidden bg-surface-container-low/50">
                      {[
                        { label: "Vérifié", color: "bg-tertiary/10 text-tertiary", title: "MacBook Air M2 256 Go", price: "590 000 FCFA", img: "https://lh3.googleusercontent.com/aida-public/AB6AXuBIvChPOE6ieaOO2yUfbxKwkO9weSiQ_1rl5LQm5EWDUMxqBNNmA0WY388lVzRxDiPW6o-Ifrnypid03WyF59mbK3yBwxMgCPmcPp_j7koUNP1yCUmtEZhJXKuNU8-zML3kh4tfPGYVDpdqXcEMXwiVFWOlEog7ETCLXLlc5uHGhLJP8CpH7P1BZjYC_EG07Zo6ksvAFZHmm82vR-YJcnYjxjwBUki0orsNJC2QkL8" },
                        { label: "Neuf", color: "bg-secondary-container/60 text-secondary", title: "Sneakers Bape Sta Original", price: "42 000 FCFA", img: "https://lh3.googleusercontent.com/aida-public/AB6AXuBXiBkGVn9jR7cwaxSZF4V5LJUEk8BF8EY_LVFIALBEm1n55V8-DK4M-TnXi2BP5-HZUyLHeTpCTjcNa2AXcc2q5yZpO6dKI8pVcv7UZmcc5xqh-oWOKVt3gRQsAdaR67HOz7rpk8nMluLh0uTGj5keasvXKVXSSlRmFoHrrgcJ2HAhWPl_bG4x6ACFgXIYo_JYtN6zEWN6-yVJTZkMU43jmogOXDYgUZJyyKrK9ko" },
                        { label: "Top Vendeur", color: "bg-tertiary/10 text-tertiary", title: "Sony Alpha 7 III + 28-70mm", price: "720 000 FCFA", img: "https://lh3.googleusercontent.com/aida-public/AB6AXuB12MpMf6c4zFS7WwclFypSujy8_ClR0gu62cLGr34sInePQsSC_VexBnzRqsIKw1B8O2O7VHs0qpxnqDnDMuhJ5-2t1ipbLfPSJVH1hwct2Jz12lz9CJpz5RlULKeVaVyQR2eJ6jK0GNOYn3zWt7MrKK0LwUjaECxgbk9w2eUOCUwlfVh8NuLYKRyDW3a8FHV9E832BBGshIRIbL9cIVMD_HZnPWT6wxj7yyjnBFo" },
                      ].map((item) => (
                        <div key={item.title} className="bg-surface-container-lowest p-2.5 rounded-2xl shadow-[0_4px_16px_rgba(19,27,45,0.04)] flex gap-2.5 items-center">
                          <div className="w-16 h-16 rounded-xl overflow-hidden relative flex-shrink-0 bg-surface-container">
                            <Image src={item.img} alt={item.title} fill className="object-cover" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <span className={`inline-block px-1.5 py-0.5 rounded-md text-[9px] font-bold ${item.color}`}>{item.label}</span>
                            <p className="font-label-md text-label-md text-on-secondary-fixed truncate">{item.title}</p>
                            <p className="font-headline-sm text-headline-sm text-primary-container font-bold">{item.price}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Floating notification */}
                <div className="absolute -bottom-4 md:-bottom-2 -left-4 md:-left-8 z-20 bg-surface-container-lowest rounded-2xl p-3 md:p-4 shadow-[0_12px_32px_rgba(19,27,45,0.12)] flex items-center gap-3 animate-bounce" style={{ animationDuration: "4s" }}>
                  <div className="w-11 h-11 rounded-full bg-tertiary/20 flex items-center justify-center text-tertiary flex-shrink-0">
                    <span className="material-symbols-outlined text-[22px]">check_circle</span>
                  </div>
                  <div>
                    <div className="flex items-center gap-1.5">
                      <span className="font-label-sm text-label-sm uppercase tracking-wider text-tertiary font-bold">Vente confirmée</span>
                      <span className="text-secondary text-[11px]">• Wave</span>
                    </div>
                    <p className="font-headline-sm text-headline-sm text-on-secondary-fixed font-bold">15 000 FCFA</p>
                    <p className="text-secondary font-body-sm text-body-sm">Awa N. · Dakar Plateau</p>
                  </div>
                </div>

                {/* Floating offers pill */}
                <div className="absolute -top-4 -right-2 md:-right-6 z-20 bg-surface-container-lowest rounded-2xl py-2 px-3.5 shadow-[0_10px_25px_rgba(19,27,45,0.1)] flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary-container text-[20px]">chat</span>
                  <div>
                    <p className="font-label-sm text-label-sm text-on-secondary-fixed font-bold">3 nouvelles offres</p>
                    <p className="text-[11px] text-secondary">Réponse moyenne en 4 min</p>
                  </div>
                </div>
              </div>

            </div>
          </div>
        </section>

        {/* ══════════════════════ CATÉGORIES ══════════════════════ */}
        <section className="w-full bg-surface py-space-xl">
          <div className="max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop">
            <div className="flex items-center justify-between mb-space-lg">
              <div>
                <span className="font-label-sm text-label-sm text-primary-container uppercase tracking-wider font-bold">Exploration</span>
                <h2 className="font-headline-lg text-headline-lg text-on-secondary-fixed">Parcourir par catégorie</h2>
              </div>
              <Link href="/decouvrir" className="font-label-lg text-label-lg text-primary-container hover:text-[#a83900] transition-colors flex items-center gap-1">
                <span>Tout explorer</span>
                <span className="material-symbols-outlined text-[18px]">chevron_right</span>
              </Link>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-3 sm:gap-4">
              {categories.map((cat) => (
                <Link
                  key={cat.id}
                  href={`/decouvrir?cat=${cat.id}`}
                  className="group flex flex-col items-center justify-center p-4 rounded-2xl bg-surface-container-lowest shadow-[0_4px_20px_rgba(19,27,45,0.04)] hover:shadow-[0_8px_24px_rgba(252,113,56,0.15)] hover:bg-primary-fixed/20 transition-all text-center"
                >
                  <div className="w-12 h-12 rounded-full bg-surface-container-low group-hover:bg-primary-container group-hover:text-white text-on-secondary-fixed flex items-center justify-center transition-colors mb-2">
                    <span className="material-symbols-outlined text-[24px]">{categoryIcon(cat)}</span>
                  </div>
                  <span className="font-label-md text-label-md text-on-secondary-fixed group-hover:text-primary-container transition-colors">{cat.nom}</span>
                </Link>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════════════════ ANNONCES RÉCENTES ══════════════════════ */}
        <section className="w-full bg-surface py-space-xl">
          <div className="max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop">
            <div className="flex items-end justify-between mb-space-lg">
              <div>
                <span className="font-label-sm text-label-sm text-primary-container uppercase tracking-wider font-bold">Sélection fraîche</span>
                <h2 className="font-headline-lg text-headline-lg text-on-secondary-fixed">Annonces récentes</h2>
              </div>
              <Link href="/decouvrir" className="font-label-lg text-label-lg text-primary-container hover:text-[#a83900] transition-colors flex items-center gap-1 font-semibold">
                <span>Voir tout</span>
                <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
              </Link>
            </div>

            {annonces.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-gutter-desktop">
                {annonces.map((item) => (
                  <ListingCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <EmptyListings />
            )}
          </div>
        </section>

        {/* ══════════════════════ COMMENT ÇA MARCHE ══════════════════════ */}
        <section id="comment-ca-marche" className="w-full bg-[#F5F0EC] py-space-xl my-4">
          <div className="max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop">
            <div className="text-center max-w-xl mx-auto mb-space-xl">
              <span className="font-label-sm text-label-sm text-primary-container uppercase tracking-wider font-bold">Simplicité &amp; Teranga</span>
              <h2 className="font-headline-lg text-headline-lg text-on-secondary-fixed mt-1">Comment ça marche ?</h2>
              <p className="font-body-md text-body-md text-secondary mt-2">
                Acheter ou vendre d&apos;occasion n&apos;a jamais été aussi direct, rapide et sécurisé au Sénégal.
              </p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {[
                { icon: "photo_camera", color: "bg-primary-fixed/40 text-primary-container", step: "ÉTAPE 01", title: "Publiez en 2 minutes", desc: "Prenez quelques photos de votre article, définissez votre prix en FCFA et ajoutez votre quartier. C'est 100% gratuit." },
                { icon: "handshake", color: "bg-secondary-fixed text-on-secondary-fixed", step: "ÉTAPE 02", title: "Négociez en direct", desc: "Échangez via la messagerie instantanée ou directement par WhatsApp avec des acheteurs proches de vous." },
                { icon: "verified_user", color: "bg-tertiary-fixed text-tertiary", step: "ÉTAPE 03", title: "Payez en sécurité", desc: "Rencontrez-vous en lieu public sécurisé ou payez par Wave / Orange Money après vérification physique de l'objet." },
              ].map((step) => (
                <div key={step.step} className="bg-surface-container-lowest p-8 rounded-3xl shadow-[0_4px_20px_rgba(19,27,45,0.04)] flex flex-col items-start hover:-translate-y-1 transition-all">
                  <div className={`w-14 h-14 rounded-2xl ${step.color} flex items-center justify-center mb-6`}>
                    <span className="material-symbols-outlined text-[30px]">{step.icon}</span>
                  </div>
                  <span className="font-label-sm text-label-sm text-primary-container font-bold tracking-wider mb-2">{step.step}</span>
                  <h3 className="font-headline-sm text-headline-sm text-on-secondary-fixed mb-2">{step.title}</h3>
                  <p className="font-body-md text-body-md text-secondary leading-relaxed">{step.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════════════════ VENDEURS DE CONFIANCE ══════════════════════ */}
        {sellers.length > 0 && (
          <section className="w-full bg-surface py-space-xl">
            <div className="max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop">
              <div className="flex items-end justify-between mb-space-lg">
                <div>
                  <span className="font-label-sm text-label-sm text-tertiary uppercase tracking-wider font-bold">Teranga Trust</span>
                  <h2 className="font-headline-lg text-headline-lg text-on-secondary-fixed">Vendeurs de confiance</h2>
                </div>
                <Link href="/decouvrir" className="font-label-lg text-label-lg text-primary-container hover:text-[#a83900] transition-colors flex items-center gap-1 font-semibold">
                  <span>Rejoindre le club vendeurs</span>
                  <span className="material-symbols-outlined text-[20px]">chevron_right</span>
                </Link>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {sellers.map((seller) => (
                  <SellerCard key={seller.id} seller={seller} />
                ))}
              </div>
            </div>
          </section>
        )}

      </main>

      {/* ══════════════════════ FOOTER ══════════════════════ */}
      <footer className="w-full bg-on-secondary-fixed text-on-secondary pt-space-xl pb-space-lg">
        <div className="max-w-[1280px] mx-auto px-margin md:px-margin-tablet lg:px-margin-desktop">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-gutter-desktop mb-space-xl">
            <div className="space-y-space-md md:col-span-1">
              <div className="flex items-center">
                <Image
                  src="/Rizen.png"
                  alt="Rizen"
                  width={100}
                  height={32}
                  className="h-8 w-auto object-contain"
                />
              </div>
              <p className="font-body-sm text-body-sm text-secondary-fixed-dim leading-relaxed">
                Le marché C2C de confiance au Sénégal. Achetez et vendez facilement à Dakar en toute sérénité.
              </p>
            </div>
            <div>
              <h4 className="font-label-lg text-label-lg text-on-secondary mb-space-md uppercase tracking-wider">Découvrir</h4>
              <ul className="space-y-space-sm">
                {["Toutes les annonces", "Véhicules & Motos", "Immobilier Dakar", "Téléphones & Tech"].map((t) => (
                  <li key={t}><Link href="/decouvrir" className="font-body-sm text-body-sm text-secondary-fixed-dim hover:text-on-secondary transition-colors">{t}</Link></li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="font-label-lg text-label-lg text-on-secondary mb-space-md uppercase tracking-wider">Aide &amp; Teranga</h4>
              <ul className="space-y-space-sm">
                {[
                  { label: "Comment ça marche", href: "#comment-ca-marche" },
                  { label: "Conseils de sécurité", href: "/conseils-securite" },
                  { label: "Centre d'assistance", href: "/centre-assistance" },
                  { label: "Contact WhatsApp", href: "https://wa.me/221787571756" },
                ].map((item) => (
                  <li key={item.label}><Link href={item.href} className="font-body-sm text-body-sm text-secondary-fixed-dim hover:text-on-secondary transition-colors">{item.label}</Link></li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="font-label-lg text-label-lg text-on-secondary mb-space-md uppercase tracking-wider">Légal</h4>
              <ul className="space-y-space-sm">
                {[
                  { label: "Conditions Générales", href: "/conditions-generales" },
                  { label: "Politique de Confidentialité", href: "/confidentialite" },
                  { label: "Règles de diffusion", href: "/regles-de-diffusion" },
                ].map((item) => (
                  <li key={item.label}><Link href={item.href} className="font-body-sm text-body-sm text-secondary-fixed-dim hover:text-on-secondary transition-colors">{item.label}</Link></li>
                ))}
              </ul>
            </div>
          </div>
          <div className="pt-space-md border-t border-secondary/20 flex flex-col sm:flex-row items-center justify-between gap-space-md text-secondary-fixed-dim font-body-sm text-body-sm">
            <span>© 2026 Rizen · Fait au Sénégal 🇸🇳</span>
            <div className="flex items-center gap-space-md">
              <Link href="/" className="material-symbols-outlined hover:text-on-secondary cursor-pointer">public</Link>
              <a href="https://wa.me/221787571756" target="_blank" rel="noopener noreferrer" className="material-symbols-outlined hover:text-on-secondary cursor-pointer">chat</a>
              <a href="https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com" target="_blank" rel="noopener noreferrer" className="material-symbols-outlined hover:text-on-secondary cursor-pointer">support_agent</a>
            </div>
          </div>
        </div>
      </footer>

    </div>
  );
}

// ─── Sub-composants ──────────────────────────────────────────────────

function ListingCard({ item }: { item: DBAnnonceWithDetails }) {
  const initials = item.vendeur
    ? sellerInitials(item.vendeur)
    : "??";
  const name = item.vendeur
    ? `${item.vendeur.prenom ?? ""} ${item.vendeur.nom?.[0] ?? ""}.`.trim()
    : "Vendeur";

  return (
    <div className="group bg-surface-container-lowest rounded-[16px] overflow-hidden shadow-[0_4px_20px_rgba(19,27,45,0.05)] hover:shadow-[0_12px_30px_rgba(19,27,45,0.1)] transition-all flex flex-col">
      <div className="relative w-full aspect-[16/10] overflow-hidden bg-surface-container-low">
        {item.firstImageUrl ? (
          <Image
            src={item.firstImageUrl}
            alt={item.titre}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-secondary">
            <span className="material-symbols-outlined text-[48px]">image</span>
          </div>
        )}
        <div className="absolute bottom-3 left-3 px-3 py-1 rounded-lg bg-surface-container-lowest text-on-secondary-fixed font-headline-sm text-headline-sm font-bold shadow-md">
          {formatFCFA(item.prix_actuel)}
        </div>
      </div>
      <div className="p-3.5 flex-1 flex flex-col justify-between space-y-3">
        <div>
          <h3 className="font-body-lg text-body-lg text-on-secondary-fixed font-semibold line-clamp-1 group-hover:text-primary-container transition-colors">
            {item.titre}
          </h3>
          <div className="flex items-center gap-2 text-secondary font-body-sm text-body-sm mt-1">
            <span className="flex items-center gap-0.5">
              <span className="material-symbols-outlined text-[16px] text-outline">location_on</span>
              {formatLocation(item.ville, item.quartier)}
            </span>
            <span>•</span>
            <span>{timeAgo(item.date_publication)}</span>
          </div>
        </div>
        <div className="pt-2 flex items-center justify-between border-t border-surface-container-low">
          <div className="flex items-center gap-2">
            {item.vendeur?.photo ? (
              <div className="w-7 h-7 rounded-full overflow-hidden relative">
                <Image src={item.vendeur.photo} alt={name} fill className="object-cover" />
              </div>
            ) : (
              <div className="w-7 h-7 rounded-full bg-secondary-container flex items-center justify-center text-xs font-bold text-on-secondary-fixed">
                {initials}
              </div>
            )}
            <span className="font-label-md text-label-md text-on-secondary-fixed">{name}</span>
          </div>
          <span className="material-symbols-outlined text-[16px] text-amber-500">star</span>
        </div>
      </div>
    </div>
  );
}

function EmptyListings() {
  return (
    <div className="col-span-4 py-16 text-center">
      <span className="material-symbols-outlined text-[56px] text-outline-variant">storefront</span>
      <p className="font-headline-sm text-headline-sm text-on-secondary-fixed mt-4">Aucune annonce pour l&apos;instant</p>
      <p className="font-body-md text-body-md text-secondary mt-2">Soyez le premier à publier une annonce !</p>
      <Link
        href="/auth/register"
        className="inline-flex items-center gap-2 mt-6 h-[52px] px-8 rounded-full bg-primary-container text-white font-label-lg text-label-lg shadow-[0_8px_24px_rgba(252,113,56,0.28)] hover:bg-[#e45f28] transition-all"
      >
        <span className="material-symbols-outlined text-[20px]">add_circle</span>
        Publier une annonce
      </Link>
    </div>
  );
}

function SellerCard({ seller }: { seller: DBTopSeller }) {
  const name = `${seller.prenom ?? ""} ${seller.nom ?? ""}`.trim() || "Vendeur";
  const initials = `${seller.prenom?.[0] ?? ""}${seller.nom?.[0] ?? ""}`.toUpperCase() || "V";

  return (
    <div className="bg-surface-container-lowest p-6 rounded-2xl shadow-[0_4px_20px_rgba(19,27,45,0.05)] hover:shadow-[0_10px_26px_rgba(19,27,45,0.08)] transition-all flex flex-col justify-between">
      <div className="flex items-start gap-4">
        <div className="relative flex-shrink-0">
          {seller.photo ? (
            <div className="w-14 h-14 rounded-full overflow-hidden relative">
              <Image src={seller.photo} alt={name} fill className="object-cover" />
            </div>
          ) : (
            <div className="w-14 h-14 rounded-full bg-primary-fixed flex items-center justify-center text-xl font-bold text-on-primary-fixed">
              {initials}
            </div>
          )}
          <span className="absolute -bottom-1 -right-1 w-5 h-5 bg-tertiary text-white rounded-full flex items-center justify-center">
            <span className="material-symbols-outlined text-[13px]">verified</span>
          </span>
        </div>
        <div className="flex-1 min-w-0">
          <h4 className="font-headline-sm text-headline-sm text-on-secondary-fixed truncate">{name}</h4>
          <p className="font-body-sm text-body-sm text-secondary">
            {seller.adresse ?? "Sénégal"}
          </p>
          {seller.avis_count > 0 && (
            <div className="flex items-center gap-1 mt-1 text-on-secondary-fixed font-label-md text-label-md">
              <span className="material-symbols-outlined text-[16px] text-amber-500" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
              <span className="font-bold">{seller.note_moyenne.toFixed(1)}</span>
              <span className="text-secondary">({seller.avis_count} avis vérifiés)</span>
            </div>
          )}
        </div>
      </div>
      <div className="mt-6 pt-4 border-t border-surface-container-low flex items-center justify-between">
        <span className="font-label-sm text-label-sm text-secondary">{seller.annonces_count} annonces en ligne</span>
        <Link href="/decouvrir" className="font-label-md text-label-md text-primary-container hover:text-[#a83900] font-bold inline-flex items-center gap-1">
          <span>Voir les annonces</span>
          <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
        </Link>
      </div>
    </div>
  );
}
