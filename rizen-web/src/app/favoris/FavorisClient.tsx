"use client";

import React, { useState, useMemo } from "react";
import Image from "next/image";
import Link from "next/link";
import {
  Heart,
  MapPin,
  CheckCircle2,
  HeartOff,
  Trash2,
  Share2,
  TrendingDown,
  ChevronDown,
  LayoutGrid,
  List,
  MessageSquare,
  ArrowUpRight,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

// ─── Types ────────────────────────────────────────────────────────────────────

interface FavoriItem {
  favoriId: number;
  dateAjout: string;
  annonce: {
    id: number;
    titre: string;
    prix_actuel: number;
    prix_initial: number;
    ville: string | null;
    quartier: string | null;
    date_publication: string;
    imageUrl: string | null;
    categorieNom: string | null;
    vendeur: { nom: string; prenom: string | null; photo: string | null; certifie?: boolean } | null;
  };
}

interface FavorisClientProps {
  items: FavoriItem[];
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function timeAgo(date: string): string {
  const diff = Date.now() - new Date(date).getTime();
  const days = Math.floor(diff / 86400000);
  if (days === 0) return "Aujourd'hui";
  if (days === 1) return "Hier";
  if (days < 7) return `Il y a ${days}j`;
  return new Date(date).toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
}

const PLACEHOLDER = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

// ─── Component ───────────────────────────────────────────────────────────────

export function FavorisClient({ items: initial }: FavorisClientProps) {
  const [items, setItems] = useState(initial);
  const [removing, setRemoving] = useState<number | null>(null);
  const [activeCategory, setActiveCategory] = useState<string>("all");
  const [sortBy, setSortBy] = useState<"recent" | "price_asc" | "price_desc">("recent");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");

  // Catégories disponibles depuis les favoris réels
  const categories = useMemo(() => {
    const seen = new Map<string, number>();
    items.forEach((i) => {
      const cat = i.annonce.categorieNom;
      if (cat) seen.set(cat, (seen.get(cat) ?? 0) + 1);
    });
    return Array.from(seen.entries()).map(([nom, count]) => ({ nom, count }));
  }, [items]);

  // Baisses de prix réelles
  const priceDropCount = useMemo(
    () => items.filter((i) => i.annonce.prix_actuel < i.annonce.prix_initial).length,
    [items]
  );

  // Filtrage + tri
  const filtered = useMemo(() => {
    let result = [...items];
    if (activeCategory !== "all") {
      result = result.filter((i) => i.annonce.categorieNom === activeCategory);
    }
    if (sortBy === "price_asc") result.sort((a, b) => a.annonce.prix_actuel - b.annonce.prix_actuel);
    else if (sortBy === "price_desc") result.sort((a, b) => b.annonce.prix_actuel - a.annonce.prix_actuel);
    // "recent" = ordre naturel (date_ajout DESC depuis le serveur)
    return result;
  }, [items, activeCategory, sortBy]);

  // ── Actions ──────────────────────────────────────────────────────────────

  const handleRemove = async (favoriId: number, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setRemoving(favoriId);
    const { error } = await supabase.from("favoris").delete().eq("id", favoriId);
    if (!error) setItems((prev) => prev.filter((i) => i.favoriId !== favoriId));
    setRemoving(null);
  };

  const handleClearAll = async () => {
    if (!confirm("Vider tous vos favoris ? Cette action est irréversible.")) return;
    const ids = items.map((i) => i.favoriId);
    await supabase.from("favoris").delete().in("id", ids);
    setItems([]);
  };

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({ title: "Mes favoris Rizen Dakar", url: window.location.href });
    } else {
      navigator.clipboard.writeText(window.location.href);
    }
  };

  // ── Empty state ───────────────────────────────────────────────────────────

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-24 text-center">
        <div className="flex h-20 w-20 items-center justify-center rounded-full bg-[#F4F3F3]">
          <HeartOff className="h-9 w-9 text-[#E3E2E2]" strokeWidth={1} />
        </div>
        <h2 className="text-xl font-bold text-[#131B2D]">Aucun favori</h2>
        <p className="max-w-xs text-sm text-[#565E73]">
          Ajoutez des annonces à vos favoris en cliquant sur le cœur.
        </p>
        <Link
          href="/decouvrir"
          className="mt-2 rounded-full bg-[#FC7138] px-6 py-2.5 text-sm font-bold text-white hover:bg-[#e05f29] transition-colors"
        >
          Explorer les annonces
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">

      {/* ── Header : titre + actions ──────────────────────────────── */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-3xl font-extrabold tracking-tight text-[#131B2D]">Mes Favoris</h1>
            <span className="rounded-full bg-[#FC7138] px-3 py-1 text-xs font-bold text-white">
              {items.length} article{items.length !== 1 ? "s" : ""}
            </span>
          </div>
          <p className="mt-1 text-xs text-[#565E73]">
            Suivez l&apos;évolution des prix de vos articles sauvegardés.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <button
            type="button"
            onClick={handleClearAll}
            className="flex items-center gap-1.5 rounded-full border border-[#E3E2E2] bg-white px-4 py-2.5 text-xs font-bold text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#131B2D] transition-all"
          >
            <Trash2 className="h-3.5 w-3.5" />
            Tout effacer
          </button>
          <button
            type="button"
            onClick={handleShare}
            className="flex items-center gap-1.5 rounded-full border border-[#131B2D] bg-white px-4 py-2.5 text-xs font-bold text-[#131B2D] hover:bg-[#F4F3F3] transition-all"
          >
            <Share2 className="h-3.5 w-3.5" />
            Partager
          </button>
        </div>
      </div>

      {/* ── Bannière baisses de prix réelles ─────────────────────── */}
      {priceDropCount > 0 && (
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-2xl bg-[#E8F8F2] border border-[#00966B]/25 p-4">
          <div className="flex items-center gap-3.5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#00966B] text-white">
              <TrendingDown className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-[#131B2D]">
                {priceDropCount} de vos favoris ont baissé de prix !
              </p>
              <p className="text-xs text-[#565E73] mt-0.5">
                Le vendeur a revu son prix à la baisse — contactez-le avant qu&apos;il change d&apos;avis.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setSortBy("price_asc")}
            className="shrink-0 rounded-full bg-[#00966B] px-5 py-2 text-xs font-bold text-white hover:bg-[#007f59] transition-all"
          >
            Voir les réductions
          </button>
        </div>
      )}

      {/* ── Filtres catégories + tri + vue ───────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        {/* Pilules catégorie */}
        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={() => setActiveCategory("all")}
            className={`rounded-full px-4 py-2 text-xs font-bold transition-all ${
              activeCategory === "all"
                ? "bg-[#FC7138] text-white shadow-sm"
                : "bg-[#F4F3F3] text-[#565E73] hover:bg-[#E3E2E2]"
            }`}
          >
            Tous ({items.length})
          </button>
          {categories.map(({ nom, count }) => (
            <button
              key={nom}
              type="button"
              onClick={() => setActiveCategory(nom)}
              className={`rounded-full px-4 py-2 text-xs font-bold transition-all ${
                activeCategory === nom
                  ? "bg-[#FC7138] text-white shadow-sm"
                  : "bg-[#F4F3F3] text-[#565E73] hover:bg-[#E3E2E2]"
              }`}
            >
              {nom} ({count})
            </button>
          ))}
        </div>

        {/* Tri + vue */}
        <div className="flex items-center gap-3 shrink-0">
          <div className="relative">
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
              className="h-10 appearance-none rounded-xl border border-[#E3E2E2] bg-white pl-4 pr-9 text-xs font-bold text-[#131B2D] outline-none cursor-pointer hover:border-[#131B2D] transition-colors"
            >
              <option value="recent">Plus récents</option>
              <option value="price_asc">Prix croissant</option>
              <option value="price_desc">Prix décroissant</option>
            </select>
            <ChevronDown className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#76777D]" />
          </div>

          <div className="flex items-center rounded-xl border border-[#E3E2E2] bg-white p-0.5">
            <button
              type="button"
              onClick={() => setViewMode("grid")}
              className={`flex h-8 w-8 items-center justify-center rounded-lg transition-colors ${viewMode === "grid" ? "bg-[#F4F3F3] text-[#131B2D]" : "text-[#76777D] hover:text-[#131B2D]"}`}
            >
              <LayoutGrid className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={() => setViewMode("list")}
              className={`flex h-8 w-8 items-center justify-center rounded-lg transition-colors ${viewMode === "list" ? "bg-[#F4F3F3] text-[#131B2D]" : "text-[#76777D] hover:text-[#131B2D]"}`}
            >
              <List className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ── Grille / Liste ───────────────────────────────────────── */}
      {filtered.length === 0 ? (
        <div className="rounded-2xl border border-[#E3E2E2] bg-white p-12 text-center space-y-3">
          <p className="text-sm font-bold text-[#131B2D]">Aucun favori dans cette catégorie.</p>
          <button
            type="button"
            onClick={() => setActiveCategory("all")}
            className="text-xs font-bold text-[#FC7138] hover:underline"
          >
            Réinitialiser les filtres
          </button>
        </div>
      ) : (
        <div className={`grid gap-5 ${viewMode === "grid" ? "grid-cols-2 md:grid-cols-3 lg:grid-cols-4" : "grid-cols-1"}`}>
          {filtered.map(({ favoriId, annonce }) => {
            const isPriceDrop = annonce.prix_actuel < annonce.prix_initial;
            const reduction = isPriceDrop ? annonce.prix_initial - annonce.prix_actuel : 0;
            const vendeurNom = annonce.vendeur
              ? `${annonce.vendeur.prenom ?? ""} ${annonce.vendeur.nom}`.trim()
              : "Vendeur";
            const isRemoving = removing === favoriId;

            return (
              <article
                key={favoriId}
                className={`group flex bg-white border border-[#E3E2E2]/70 rounded-2xl shadow-[0_4px_20px_rgba(19,27,45,0.04)] overflow-hidden transition-all duration-200 hover:-translate-y-1 hover:shadow-[0_12px_28px_rgba(19,27,45,0.08)] ${viewMode === "list" ? "flex-row" : "flex-col"}`}
              >
                {/* Image */}
                <div className={`relative overflow-hidden bg-[#F4F3F3] ${viewMode === "list" ? "w-48 shrink-0" : "aspect-[16/10] w-full"}`}>
                  <Image
                    src={annonce.imageUrl ?? PLACEHOLDER}
                    alt={annonce.titre}
                    fill
                    sizes={viewMode === "grid" ? "(max-width: 768px) 50vw, 25vw" : "192px"}
                    className="object-cover transition-transform duration-300 group-hover:scale-105"
                  />

                  {/* Badge baisse de prix */}
                  {isPriceDrop && (
                    <span className="absolute top-3 left-3 inline-flex items-center gap-1 rounded-full bg-[#00966B] px-2.5 py-1 text-[11px] font-extrabold text-white shadow-sm">
                      <TrendingDown className="h-3 w-3" />
                      -{reduction.toLocaleString("fr-FR")} FCFA
                    </span>
                  )}

                  {/* Badge catégorie */}
                  {annonce.categorieNom && (
                    <span className="absolute bottom-3 left-3 rounded-lg bg-[#131B2D]/85 backdrop-blur-sm px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white">
                      {annonce.categorieNom}
                    </span>
                  )}

                  {/* Bouton retirer */}
                  <button
                    type="button"
                    onClick={(e) => handleRemove(favoriId, e)}
                    disabled={isRemoving}
                    aria-label="Retirer des favoris"
                    className="absolute top-3 right-3 flex h-8 w-8 items-center justify-center rounded-full bg-white/95 backdrop-blur-sm shadow-sm transition-transform active:scale-90 hover:bg-white"
                  >
                    <Heart className={`h-4 w-4 transition-all ${isRemoving ? "opacity-40" : "fill-[#FC7138] text-[#FC7138]"}`} />
                  </button>
                </div>

                {/* Contenu */}
                <div className="flex flex-1 flex-col p-4">
                  {/* Prix */}
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="text-xl font-black text-[#131B2D] tracking-tight leading-none">
                        {annonce.prix_actuel.toLocaleString("fr-FR")} FCFA
                      </p>
                      {isPriceDrop && (
                        <p className="mt-0.5 text-xs font-semibold text-[#76777D] line-through">
                          {annonce.prix_initial.toLocaleString("fr-FR")} FCFA
                        </p>
                      )}
                    </div>
                    {isPriceDrop && (
                      <span className="rounded-full bg-[#E8F8F2] px-2.5 py-0.5 text-[11px] font-bold text-[#00966B] shrink-0">
                        En baisse
                      </span>
                    )}
                  </div>

                  {/* Titre */}
                  <Link href={`/annonces/${annonce.id}`} className="mt-2.5 block flex-1">
                    <h3 className="line-clamp-2 text-sm font-bold text-[#131B2D] group-hover:text-[#FC7138] transition-colors leading-snug">
                      {annonce.titre}
                    </h3>
                  </Link>

                  {/* Vendeur */}
                  <div className="mt-3 flex items-center gap-2 border-t border-[#F4F3F3] pt-3">
                    <div className="relative h-7 w-7 shrink-0 rounded-full overflow-hidden bg-[#FFDBBF]">
                      {annonce.vendeur?.photo ? (
                        <Image src={annonce.vendeur.photo} alt={vendeurNom} fill className="object-cover" />
                      ) : (
                        <span className="flex h-full w-full items-center justify-center text-[9px] font-bold text-[#FC7138]">
                          {vendeurNom[0]?.toUpperCase()}
                        </span>
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1">
                        <span className="truncate text-xs font-bold text-[#131B2D]">{vendeurNom}</span>
                        {annonce.vendeur?.certifie && (
                          <CheckCircle2 className="h-3.5 w-3.5 fill-[#00966B] text-white shrink-0" />
                        )}
                      </div>
                      <div className="flex items-center gap-1 text-[11px] text-[#76777D]">
                        <MapPin className="h-3 w-3 shrink-0" />
                        <span className="truncate">{annonce.quartier ?? annonce.ville ?? "Dakar"}</span>
                      </div>
                    </div>
                    <span className="text-[11px] text-[#76777D] shrink-0">{timeAgo(annonce.date_publication)}</span>
                  </div>

                  {/* CTAs */}
                  <div className="mt-4 grid grid-cols-2 gap-2">
                    <Link
                      href={`/annonces/${annonce.id}`}
                      className="flex h-9 items-center justify-center gap-1.5 rounded-full border border-[#E3E2E2] bg-white text-xs font-bold text-[#131B2D] hover:bg-[#F4F3F3] transition-all"
                    >
                      <ArrowUpRight className="h-3.5 w-3.5" />
                      Voir
                    </Link>
                    <Link
                      href={`/messages`}
                      className="flex h-9 items-center justify-center gap-1.5 rounded-full bg-[#FC7138] text-xs font-bold text-white hover:bg-[#e05f29] transition-all shadow-sm"
                    >
                      <MessageSquare className="h-3.5 w-3.5" />
                      Message
                    </Link>
                  </div>
                </div>
              </article>
            );
          })}
        </div>
      )}
    </div>
  );
}
