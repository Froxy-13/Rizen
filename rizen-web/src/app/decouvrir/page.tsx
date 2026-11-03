"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import Image from "next/image";
import { supabase } from "@/lib/supabase";
import { NavbarDecouvrir } from "@/components/layout/NavbarDecouvrir";

// ─── Constants ────────────────────────────────────────────────────────
const PAGE_SIZE = 12;
const MAX_PRIX = 500000;

const TRENDING = ["PlayStation 5", "Toyota Yaris", "iPhone 14 Pro", "Canapé salon"];

const CAT_ICONS: Record<string, string> = {
  électronique: "smartphone",
  electronique: "smartphone",
  "vêtements": "apparel",
  vetements: "apparel",
  "vêtements & mode": "apparel",
  maison: "chair",
  "maison & décoration": "chair",
  véhicules: "two_wheeler",
  vehicules: "two_wheeler",
  sport: "fitness_center",
  beauté: "spa",
  beaute: "spa",
  immobilier: "apartment",
  livres: "menu_book",
};

function catIcon(nom: string) {
  return CAT_ICONS[nom.toLowerCase()] ?? "category";
}

// ─── Types ────────────────────────────────────────────────────────────
interface AnnonceCard {
  id: number;
  titre: string;
  prix_actuel: number;
  prix_initial: number;
  ville: string | null;
  quartier: string | null;
  date_publication: string;
  utilisateur_id: string;
  categorie_id: number | null;
  firstImageUrl: string | null;
  vendeur: { prenom: string | null; nom: string | null; photo: string | null } | null;
  note_moyenne: number | null;
  avis_count: number;
}

interface Categorie { id: number; nom: string }

interface Filters {
  search: string;
  categorieId: number | null;
  ville: string;
  quartier: string;
  minPrix: number;
  maxPrix: number;
}

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

function initials(prenom: string | null, nom: string | null): string {
  return ((prenom?.[0] ?? "") + (nom?.[0] ?? "")).toUpperCase() || "?";
}

const AVATAR_COLORS = [
  "bg-primary-container text-white",
  "bg-tertiary-container text-on-tertiary",
  "bg-secondary-container text-on-secondary-container",
  "bg-tertiary/20 text-tertiary",
];

function avatarColor(id: string): string {
  const n = id.charCodeAt(0) + id.charCodeAt(1);
  return AVATAR_COLORS[n % AVATAR_COLORS.length];
}

// ─── Skeleton card ────────────────────────────────────────────────────
function SkeletonCard() {
  return (
    <div className="rounded-3xl bg-surface-container-lowest shadow-card overflow-hidden animate-pulse">
      <div className="h-44 bg-surface-container-high" />
      <div className="p-4 space-y-2.5">
        <div className="h-5 w-24 bg-surface-container-high rounded-full" />
        <div className="h-4 w-full bg-surface-container rounded-full" />
        <div className="h-4 w-3/4 bg-surface-container rounded-full" />
        <div className="h-3 w-1/2 bg-surface-container rounded-full mt-3" />
      </div>
    </div>
  );
}

// ─── Annonce card ─────────────────────────────────────────────────────
function AnnonceCardItem({ item }: { item: AnnonceCard }) {
  const isNegociable = item.prix_actuel < item.prix_initial;
  return (
    <Link href={`/annonces/${item.id}`} className="group block rounded-3xl bg-surface-container-lowest shadow-card overflow-hidden hover:-translate-y-1 transition-all duration-200">
      <div className="relative h-44 bg-surface-container-high overflow-hidden">
        {item.firstImageUrl ? (
          <Image
            src={item.firstImageUrl}
            alt={item.titre}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="material-symbols-outlined text-[48px] text-surface-container-highest">image</span>
          </div>
        )}
        {isNegociable && (
          <span className="absolute top-3 left-3 px-2 py-0.5 rounded-full bg-primary-container text-white text-label-sm font-semibold">
            Négociable
          </span>
        )}
        <button
          onClick={(e) => e.preventDefault()}
          className="absolute top-3 right-3 w-8 h-8 rounded-full bg-surface-container-lowest/80 backdrop-blur flex items-center justify-center hover:bg-surface-container-lowest transition-colors"
          aria-label="Sauvegarder"
        >
          <span className="material-symbols-outlined text-[18px] text-secondary">favorite</span>
        </button>
      </div>
      <div className="p-4">
        <p className="text-headline-sm text-primary-container font-bold mb-1">{formatFCFA(item.prix_actuel)}</p>
        <p className="text-body-md text-on-surface font-medium line-clamp-2 mb-3">{item.titre}</p>
        <div className="flex items-center gap-1.5 text-label-sm text-secondary mb-2">
          <span className="material-symbols-outlined text-[14px]">location_on</span>
          <span className="truncate">{item.quartier ? `${item.quartier}, ${item.ville}` : (item.ville ?? "Sénégal")}</span>
          <span className="mx-1">·</span>
          <span className="shrink-0">{timeAgo(item.date_publication)}</span>
        </div>
        {item.vendeur && (
          <div className="flex items-center gap-2 pt-2 border-t border-surface-container-highest">
            {item.vendeur.photo ? (
              <div className="relative w-7 h-7 rounded-full overflow-hidden shrink-0">
                <Image src={item.vendeur.photo} alt="" fill className="object-cover" />
              </div>
            ) : (
              <div className={`w-7 h-7 rounded-full flex items-center justify-center text-label-sm font-bold shrink-0 ${avatarColor(item.utilisateur_id)}`}>
                {initials(item.vendeur.prenom, item.vendeur.nom)}
              </div>
            )}
            <span className="text-label-sm text-secondary truncate">
              {item.vendeur.prenom} {item.vendeur.nom?.[0]}.
            </span>
            {item.note_moyenne !== null && item.note_moyenne > 0 && (
              <div className="ml-auto flex items-center gap-0.5 text-label-sm text-secondary shrink-0">
                <span className="material-symbols-outlined text-primary-container text-[14px]">star</span>
                {item.note_moyenne.toFixed(1)}
              </div>
            )}
          </div>
        )}
      </div>
    </Link>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────
export default function DecouvrirPage() {
  const [annonces, setAnnonces] = useState<AnnonceCard[]>([]);
  const [categories, setCategories] = useState<Categorie[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [offset, setOffset] = useState(0);
  const [view, setView] = useState<"grid" | "list">("grid");
  const [sort, setSort] = useState<"recent" | "prix_asc" | "prix_desc">("recent");
  const [showFilters, setShowFilters] = useState(false);

  const [filters, setFilters] = useState<Filters>({
    search: "",
    categorieId: null,
    ville: "",
    quartier: "",
    minPrix: 0,
    maxPrix: MAX_PRIX,
  });
  const [pendingFilters, setPendingFilters] = useState<Filters>(filters);

  // active chips (applied filters)
  const activeChips: { label: string; key: keyof Filters }[] = [];
  if (filters.ville) activeChips.push({ label: filters.ville, key: "ville" });
  if (filters.categorieId) {
    const cat = categories.find((c) => c.id === filters.categorieId);
    if (cat) activeChips.push({ label: cat.nom, key: "categorieId" });
  }

  const buildQuery = useCallback(
    (f: Filters, currentSort: string, currentOffset: number) => {
      let q = supabase
        .from("annonces")
        .select(
          "id, titre, prix_actuel, prix_initial, ville, quartier, date_publication, utilisateur_id, categorie_id, images_annonce(url_image, ordre)",
          { count: "exact" }
        )
        .eq("statut", "active");

      if (f.search.trim()) q = q.ilike("titre", `%${f.search.trim()}%`);
      if (f.categorieId) q = q.eq("categorie_id", f.categorieId);
      if (f.ville.trim()) q = q.ilike("ville", `%${f.ville.trim()}%`);
      if (f.quartier.trim()) q = q.ilike("quartier", `%${f.quartier.trim()}%`);
      if (f.minPrix > 0) q = q.gte("prix_actuel", f.minPrix);
      if (f.maxPrix < MAX_PRIX) q = q.lte("prix_actuel", f.maxPrix);

      if (currentSort === "prix_asc") q = q.order("prix_actuel", { ascending: true });
      else if (currentSort === "prix_desc") q = q.order("prix_actuel", { ascending: false });
      else q = q.order("date_publication", { ascending: false });

      q = q.range(currentOffset, currentOffset + PAGE_SIZE - 1);
      return q;
    },
    []
  );

  const loadAnnonces = useCallback(
    async (f: Filters, currentSort: string, append = false, startOffset = 0) => {
      if (!append) setLoading(true);
      else setLoadingMore(true);

      const currentOffset = append ? startOffset + PAGE_SIZE : 0;

      try {
        const { data, count, error } = await buildQuery(f, currentSort, currentOffset);
        if (error) throw error;

        const rawAnnonces = data || [];

        // Fetch profils
        const uids = Array.from(new Set(rawAnnonces.map((a) => a.utilisateur_id).filter(Boolean)));
        const [profilsRes, avisRes] = await Promise.all([
          uids.length
            ? supabase.from("profils").select("id, prenom, nom, photo").in("id", uids)
            : Promise.resolve({ data: [] }),
          uids.length
            ? supabase.from("avis").select("vendeur_id, note").in("vendeur_id", uids)
            : Promise.resolve({ data: [] }),
        ]);

        const profils = profilsRes.data || [];
        const avis = avisRes.data || [];

        const mapped: AnnonceCard[] = rawAnnonces.map((a) => {
          const imgs = ((a.images_annonce as { url_image: string; ordre: number }[]) || [])
            .sort((x, y) => (x.ordre ?? 0) - (y.ordre ?? 0));
          const profil = profils.find((p) => p.id === a.utilisateur_id);
          const sellerAvis = avis.filter((av) => av.vendeur_id === a.utilisateur_id);
          const note =
            sellerAvis.length > 0
              ? sellerAvis.reduce((s, av) => s + (av.note ?? 0), 0) / sellerAvis.length
              : null;
          return {
            id: a.id,
            titre: a.titre,
            prix_actuel: a.prix_actuel,
            prix_initial: a.prix_initial ?? a.prix_actuel,
            ville: a.ville,
            quartier: a.quartier,
            date_publication: a.date_publication,
            utilisateur_id: a.utilisateur_id,
            categorie_id: a.categorie_id,
            firstImageUrl: imgs[0]?.url_image ?? null,
            vendeur: profil ? { prenom: profil.prenom, nom: profil.nom, photo: profil.photo } : null,
            note_moyenne: note !== null ? Math.round(note * 10) / 10 : null,
            avis_count: sellerAvis.length,
          };
        });

        if (append) {
          setAnnonces((prev) => [...prev, ...mapped]);
          setOffset(currentOffset);
        } else {
          setAnnonces(mapped);
          setOffset(0);
        }
        setTotal(count ?? 0);
      } catch {
        // silently fail
      } finally {
        setLoading(false);
        setLoadingMore(false);
      }
    },
    [buildQuery]
  );

  // Initial load + categories
  useEffect(() => {
    supabase.from("categories").select("id, nom").order("id").limit(12).then(({ data }) => {
      setCategories(data || []);
    });
    loadAnnonces(filters, sort);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function applyFilters() {
    setFilters(pendingFilters);
    setShowFilters(false);
    loadAnnonces(pendingFilters, sort);
  }

  function resetFilters() {
    const empty: Filters = { search: "", categorieId: null, ville: "", quartier: "", minPrix: 0, maxPrix: MAX_PRIX };
    setFilters(empty);
    setPendingFilters(empty);
    loadAnnonces(empty, sort);
  }

  function removeChip(key: keyof Filters) {
    const updated = { ...filters, [key]: key === "categorieId" ? null : key === "minPrix" ? 0 : key === "maxPrix" ? MAX_PRIX : "" };
    setFilters(updated);
    setPendingFilters(updated);
    loadAnnonces(updated, sort);
  }

  function changeSort(newSort: "recent" | "prix_asc" | "prix_desc") {
    setSort(newSort);
    loadAnnonces(filters, newSort);
  }

  function selectCategory(id: number | null) {
    const updated = { ...filters, categorieId: id };
    setFilters(updated);
    setPendingFilters(updated);
    loadAnnonces(updated, sort);
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    loadAnnonces(pendingFilters, sort);
    setFilters(pendingFilters);
  }

  return (
    <div className="min-h-screen bg-surface">

      <NavbarDecouvrir />

      {/* ── Search hero ── */}
      <div className="bg-on-secondary-fixed pb-6 pt-4">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 lg:px-8">
          <form onSubmit={handleSearch}>
            <div className="bg-surface-container-lowest rounded-2xl shadow-lg flex flex-col sm:flex-row items-stretch gap-0 overflow-hidden">
              {/* Search input */}
              <div className="flex items-center gap-2 flex-1 px-4 py-3 border-b sm:border-b-0 sm:border-r border-surface-container-highest">
                <span className="material-symbols-outlined text-secondary text-[20px] shrink-0">search</span>
                <input
                  type="text"
                  value={pendingFilters.search}
                  onChange={(e) => setPendingFilters({ ...pendingFilters, search: e.target.value })}
                  placeholder="Rechercher une annonce..."
                  className="flex-1 bg-transparent text-on-surface text-body-md placeholder:text-secondary outline-none"
                />
              </div>
              {/* Category select */}
              <div className="relative flex items-center px-4 border-b sm:border-b-0 sm:border-r border-surface-container-highest min-w-[160px]">
                <span className="material-symbols-outlined text-secondary text-[18px] shrink-0 mr-2 pointer-events-none">category</span>
                <select
                  value={pendingFilters.categorieId ?? ""}
                  onChange={(e) => setPendingFilters({ ...pendingFilters, categorieId: e.target.value ? Number(e.target.value) : null })}
                  className="flex-1 bg-transparent text-on-surface text-body-md appearance-none outline-none py-3 pr-6 cursor-pointer"
                >
                  <option value="">Toutes catégories</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>{c.nom}</option>
                  ))}
                </select>
                <span className="material-symbols-outlined text-secondary text-[18px] absolute right-3 pointer-events-none">expand_more</span>
              </div>
              {/* Ville */}
              <div className="flex items-center gap-2 px-4 border-b sm:border-b-0 sm:border-r border-surface-container-highest min-w-[140px]">
                <span className="material-symbols-outlined text-secondary text-[18px] shrink-0">location_on</span>
                <input
                  type="text"
                  value={pendingFilters.ville}
                  onChange={(e) => setPendingFilters({ ...pendingFilters, ville: e.target.value })}
                  placeholder="Dakar"
                  className="flex-1 bg-transparent text-on-surface text-body-md placeholder:text-secondary outline-none py-3"
                />
              </div>
              {/* Button */}
              <button
                type="submit"
                className="flex items-center justify-center gap-2 bg-primary-container text-white text-label-lg font-semibold px-6 py-3 hover:opacity-90 transition-opacity"
              >
                <span className="material-symbols-outlined text-[18px]">tune</span>
                Rechercher
              </button>
            </div>
          </form>

          {/* Trending */}
          <div className="flex flex-wrap items-center gap-2 mt-3">
            <span className="text-label-sm text-secondary-fixed-dim">Tendances à Dakar :</span>
            {TRENDING.map((t) => (
              <button
                key={t}
                onClick={() => {
                  const updated = { ...pendingFilters, search: t };
                  setPendingFilters(updated);
                  setFilters(updated);
                  loadAnnonces(updated, sort);
                }}
                className="text-label-sm text-secondary-fixed-dim hover:text-on-secondary underline-offset-2 hover:underline transition-colors"
              >
                {t}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Category tabs ── */}
      <div className="bg-surface-container-lowest border-b border-surface-container-highest sticky top-[68px] z-40">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide py-3">
            <button
              onClick={() => selectCategory(null)}
              className={`shrink-0 inline-flex items-center gap-1.5 h-9 px-4 rounded-full text-label-md font-semibold transition-colors ${
                !filters.categorieId
                  ? "bg-primary-container text-white"
                  : "bg-surface-container text-secondary hover:bg-surface-container-high"
              }`}
            >
              Tous
            </button>
            {categories.map((c) => (
              <button
                key={c.id}
                onClick={() => selectCategory(c.id)}
                className={`shrink-0 inline-flex items-center gap-1.5 h-9 px-4 rounded-full text-label-md transition-colors ${
                  filters.categorieId === c.id
                    ? "bg-primary-container text-white font-semibold"
                    : "bg-surface-container text-secondary hover:bg-surface-container-high"
                }`}
              >
                <span className="material-symbols-outlined text-[16px]">{catIcon(c.nom)}</span>
                {c.nom}
              </button>
            ))}
            <div className="ml-auto shrink-0 flex items-center gap-1">
              <span className="text-label-sm text-secondary whitespace-nowrap">Trier par :</span>
              <select
                value={sort}
                onChange={(e) => changeSort(e.target.value as "recent" | "prix_asc" | "prix_desc")}
                className="bg-transparent text-label-md text-on-surface outline-none cursor-pointer pr-1"
              >
                <option value="recent">Plus récent</option>
                <option value="prix_asc">Prix croissant</option>
                <option value="prix_desc">Prix décroissant</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* ── Main ── */}
      <div className="max-w-[1280px] mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex gap-6">

          {/* ── Sidebar ── */}
          <aside className="hidden lg:block w-60 shrink-0">
            <div className="bg-surface-container-lowest rounded-3xl shadow-card p-5 sticky top-[124px] space-y-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-on-secondary-fixed">
                  <span className="material-symbols-outlined text-[20px]">tune</span>
                  <span className="text-label-lg font-semibold">Filtres</span>
                </div>
                <button onClick={resetFilters} className="text-label-sm text-secondary hover:text-primary-container transition-colors">
                  Réinitialiser
                </button>
              </div>

              {/* Prix */}
              <div>
                <p className="text-label-md text-on-surface font-semibold mb-3">Prix (FCFA)</p>
                <input
                  type="range"
                  min={0}
                  max={MAX_PRIX}
                  step={5000}
                  value={pendingFilters.maxPrix}
                  onChange={(e) => setPendingFilters({ ...pendingFilters, maxPrix: Number(e.target.value) })}
                  className="w-full accent-primary-container"
                />
                <div className="flex gap-2 mt-2">
                  <div className="flex-1 bg-surface-container rounded-xl p-2 text-center">
                    <p className="text-label-sm text-secondary">Min</p>
                    <p className="text-label-md text-on-surface font-medium">{formatFCFA(pendingFilters.minPrix)}</p>
                  </div>
                  <div className="flex-1 bg-surface-container rounded-xl p-2 text-center">
                    <p className="text-label-sm text-secondary">Max</p>
                    <p className="text-label-md text-on-surface font-medium">
                      {pendingFilters.maxPrix >= MAX_PRIX ? "500 000+" : formatFCFA(pendingFilters.maxPrix)}
                    </p>
                  </div>
                </div>
              </div>

              {/* Localisation */}
              <div>
                <p className="text-label-md text-on-surface font-semibold mb-2">Localisation</p>
                <div className="relative mb-2">
                  <select
                    value={pendingFilters.ville}
                    onChange={(e) => setPendingFilters({ ...pendingFilters, ville: e.target.value })}
                    className="w-full h-10 pl-3 pr-8 rounded-xl bg-surface-container border border-surface-container-highest text-body-sm text-on-surface appearance-none outline-none focus:border-primary-container"
                  >
                    <option value="">Dakar (Toutes zones)</option>
                    <option value="Dakar">Dakar</option>
                    <option value="Thiès">Thiès</option>
                    <option value="Saint-Louis">Saint-Louis</option>
                    <option value="Ziguinchor">Ziguinchor</option>
                  </select>
                  <span className="material-symbols-outlined absolute right-2 top-1/2 -translate-y-1/2 text-secondary text-[16px] pointer-events-none">expand_more</span>
                </div>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[16px]">location_on</span>
                  <input
                    type="text"
                    value={pendingFilters.quartier}
                    onChange={(e) => setPendingFilters({ ...pendingFilters, quartier: e.target.value })}
                    placeholder="Quartier (ex : Almadies, Plateau)"
                    className="w-full h-10 pl-9 pr-3 rounded-xl bg-surface-container border border-surface-container-highest text-body-sm text-on-surface placeholder:text-secondary outline-none focus:border-primary-container"
                  />
                </div>
              </div>

              {/* Catégorie */}
              <div>
                <p className="text-label-md text-on-surface font-semibold mb-2">Catégorie</p>
                <div className="space-y-1.5">
                  {categories.slice(0, 5).map((c) => (
                    <label key={c.id} className="flex items-center gap-2 cursor-pointer group">
                      <input
                        type="radio"
                        name="cat"
                        checked={pendingFilters.categorieId === c.id}
                        onChange={() => setPendingFilters({ ...pendingFilters, categorieId: c.id })}
                        className="accent-primary-container"
                      />
                      <span className="text-body-sm text-on-surface group-hover:text-primary-container transition-colors flex-1">{c.nom}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Profils vérifiés */}
              <label className="flex items-start gap-3 p-3 rounded-2xl bg-surface-container cursor-pointer">
                <div className="flex items-center justify-center w-5 h-5 mt-0.5">
                  <input type="checkbox" className="accent-primary-container" />
                </div>
                <div>
                  <p className="text-label-md text-on-surface font-semibold flex items-center gap-1">
                    <span className="material-symbols-outlined text-tertiary text-[16px]">verified_user</span>
                    Profils vérifiés Teranga
                  </p>
                  <p className="text-label-sm text-secondary mt-0.5">Uniquement les membres certifiés par CNI</p>
                </div>
              </label>

              <button
                onClick={applyFilters}
                className="w-full h-[48px] rounded-full bg-primary-container text-white text-label-lg font-semibold hover:opacity-90 active:scale-[0.98] transition-all"
              >
                Appliquer les filtres
              </button>
            </div>
          </aside>

          {/* ── Content ── */}
          <div className="flex-1 min-w-0">

            {/* Results header */}
            <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
              <div className="flex items-center gap-3 flex-wrap">
                <div>
                  {loading ? (
                    <div className="h-6 w-48 bg-surface-container animate-pulse rounded-full" />
                  ) : (
                    <span className="text-headline-sm text-on-secondary-fixed font-bold">
                      {new Intl.NumberFormat("fr-FR").format(total)} annonces trouvées
                    </span>
                  )}
                </div>
                {activeChips.map((chip) => (
                  <span key={chip.key} className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-surface-container text-label-sm text-on-surface">
                    {chip.label}
                    <button onClick={() => removeChip(chip.key)} className="ml-1 hover:text-error transition-colors">
                      <span className="material-symbols-outlined text-[14px]">close</span>
                    </button>
                  </span>
                ))}
              </div>
              <div className="flex items-center gap-2">
                {/* Mobile filters button */}
                <button
                  onClick={() => setShowFilters(true)}
                  className="lg:hidden inline-flex items-center gap-1.5 h-9 px-3 rounded-full bg-surface-container text-label-md text-secondary hover:bg-surface-container-high transition-colors"
                >
                  <span className="material-symbols-outlined text-[18px]">tune</span>
                  Filtres
                </button>
                {/* View toggle */}
                <div className="flex items-center gap-1 bg-surface-container rounded-full p-1">
                  <button
                    onClick={() => setView("grid")}
                    className={`w-8 h-7 rounded-full flex items-center justify-center transition-colors ${view === "grid" ? "bg-surface-container-lowest shadow-sm text-on-surface" : "text-secondary"}`}
                  >
                    <span className="material-symbols-outlined text-[18px]">grid_view</span>
                  </button>
                  <button
                    onClick={() => setView("list")}
                    className={`w-8 h-7 rounded-full flex items-center justify-center transition-colors ${view === "list" ? "bg-surface-container-lowest shadow-sm text-on-surface" : "text-secondary"}`}
                  >
                    <span className="material-symbols-outlined text-[18px]">view_list</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Grid */}
            {loading ? (
              <div className={`grid gap-4 ${view === "grid" ? "grid-cols-1 sm:grid-cols-2 xl:grid-cols-3" : "grid-cols-1"}`}>
                {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} />)}
              </div>
            ) : annonces.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-20 gap-4 text-center">
                <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center">
                  <span className="material-symbols-outlined text-[32px] text-secondary">search_off</span>
                </div>
                <p className="text-headline-sm text-on-surface">Aucune annonce trouvée</p>
                <p className="text-body-md text-secondary max-w-sm">Essayez d&apos;ajuster vos filtres ou de rechercher un autre terme.</p>
                <button onClick={resetFilters} className="inline-flex items-center gap-2 h-[44px] px-5 rounded-full bg-primary-container text-white text-label-lg hover:opacity-90 transition-all">
                  Réinitialiser les filtres
                </button>
              </div>
            ) : (
              <>
                <div className={`grid gap-4 ${view === "grid" ? "grid-cols-1 sm:grid-cols-2 xl:grid-cols-3" : "grid-cols-1"}`}>
                  {annonces.map((a) => <AnnonceCardItem key={a.id} item={a} />)}
                  {loadingMore && Array.from({ length: 3 }).map((_, i) => <SkeletonCard key={`more-${i}`} />)}
                </div>

                {/* Infinite scroll indicator */}
                <div className="flex items-center justify-between mt-4 text-label-sm text-secondary">
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-tertiary-container animate-pulse" />
                    Chargement continu des annonces récentes…
                  </div>
                  <span>Rafraîchissement automatique</span>
                </div>

                {/* Load more */}
                {annonces.length < total && (
                  <div className="flex flex-col items-center gap-2 mt-8">
                    <button
                      onClick={() => loadAnnonces(filters, sort, true, offset)}
                      disabled={loadingMore}
                      className="inline-flex items-center gap-2 h-[52px] px-8 rounded-full bg-surface-container-lowest shadow-card text-on-secondary-fixed text-label-lg font-semibold hover:bg-surface-container-low transition-all disabled:opacity-60"
                    >
                      <span className="material-symbols-outlined text-[20px]">refresh</span>
                      Charger plus d&apos;annonces
                    </button>
                    <p className="text-label-sm text-secondary">
                      Affichage de {annonces.length} sur {new Intl.NumberFormat("fr-FR").format(total)} annonces vérifiées
                    </p>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>

      {/* ── Mobile filters drawer ── */}
      {showFilters && (
        <div className="fixed inset-0 z-50 flex lg:hidden">
          <div className="absolute inset-0 bg-on-secondary-fixed/60 backdrop-blur-sm" onClick={() => setShowFilters(false)} />
          <div className="relative ml-auto w-80 bg-surface-container-lowest h-full overflow-y-auto p-5 space-y-6 shadow-2xl">
            <div className="flex items-center justify-between">
              <span className="text-headline-sm text-on-secondary-fixed font-semibold">Filtres</span>
              <button onClick={() => setShowFilters(false)}>
                <span className="material-symbols-outlined text-secondary text-[24px]">close</span>
              </button>
            </div>
            {/* Prix */}
            <div>
              <p className="text-label-md text-on-surface font-semibold mb-3">Prix maximum (FCFA)</p>
              <input type="range" min={0} max={MAX_PRIX} step={5000} value={pendingFilters.maxPrix} onChange={(e) => setPendingFilters({ ...pendingFilters, maxPrix: Number(e.target.value) })} className="w-full accent-primary-container" />
              <p className="text-label-sm text-secondary mt-1">
                {pendingFilters.maxPrix >= MAX_PRIX ? "500 000+ FCFA" : formatFCFA(pendingFilters.maxPrix)}
              </p>
            </div>
            {/* Catégorie */}
            <div>
              <p className="text-label-md text-on-surface font-semibold mb-2">Catégorie</p>
              <div className="space-y-1.5">
                {categories.map((c) => (
                  <label key={c.id} className="flex items-center gap-2 cursor-pointer">
                    <input type="radio" name="cat-mobile" checked={pendingFilters.categorieId === c.id} onChange={() => setPendingFilters({ ...pendingFilters, categorieId: c.id })} className="accent-primary-container" />
                    <span className="text-body-sm text-on-surface">{c.nom}</span>
                  </label>
                ))}
              </div>
            </div>
            <div className="flex gap-3 pt-2">
              <button onClick={resetFilters} className="flex-1 h-[48px] rounded-full border border-surface-container-highest text-on-surface text-label-lg hover:bg-surface-container transition-colors">
                Réinitialiser
              </button>
              <button onClick={applyFilters} className="flex-1 h-[48px] rounded-full bg-primary-container text-white text-label-lg font-semibold hover:opacity-90 transition-all">
                Appliquer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Footer ── */}
      <footer className="w-full bg-on-secondary-fixed text-on-secondary mt-12 pt-12 pb-8">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8 mb-10">
            <div>
              <div className="rounded-[10px] overflow-hidden w-fit mb-3">
                <Image src="/Rizen.png" alt="Rizen" width={80} height={32} className="h-8 w-auto object-contain" />
              </div>
              <p className="text-body-sm text-secondary-fixed-dim leading-relaxed">
                Le marché C2C de confiance au Sénégal. Achetez et vendez facilement à Dakar en toute sérénité.
              </p>
            </div>
            <div>
              <h4 className="text-label-lg text-on-secondary mb-4 uppercase tracking-wider">Découvrir</h4>
              <ul className="space-y-2">
                {["Toutes les annonces", "Véhicules & Motos", "Immobilier Dakar", "Téléphones & Tech"].map((l) => (
                  <li key={l}><Link href="/decouvrir" className="text-body-sm text-secondary-fixed-dim hover:text-on-secondary transition-colors">{l}</Link></li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="text-label-lg text-on-secondary mb-4 uppercase tracking-wider">Aide &amp; Teranga</h4>
              <ul className="space-y-2">
                {[
                  { label: "Comment ça marche", href: "#" },
                  { label: "Conseils de sécurité", href: "/conseils-securite" },
                  { label: "Centre d'assistance", href: "/centre-assistance" },
                  { label: "Contact WhatsApp", href: "https://wa.me/221787571756" },
                ].map((l) => (
                  <li key={l.label}><Link href={l.href} className="text-body-sm text-secondary-fixed-dim hover:text-on-secondary transition-colors">{l.label}</Link></li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="text-label-lg text-on-secondary mb-4 uppercase tracking-wider">Légal</h4>
              <ul className="space-y-2">
                {[
                  { label: "Conditions Générales", href: "/conditions-generales" },
                  { label: "Politique de Confidentialité", href: "/confidentialite" },
                  { label: "Règles de diffusion", href: "/regles-de-diffusion" },
                ].map((l) => (
                  <li key={l.label}><Link href={l.href} className="text-body-sm text-secondary-fixed-dim hover:text-on-secondary transition-colors">{l.label}</Link></li>
                ))}
              </ul>
            </div>
          </div>
          <div className="pt-6 border-t border-secondary/20 flex flex-col sm:flex-row items-center justify-between gap-4 text-secondary-fixed-dim text-body-sm">
            <span>© 2026 Rizen · Fait au Sénégal</span>
            <div className="flex items-center gap-4">
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
