"use client";

import React, { useState } from "react";
import Image from "next/image";
import { Store, Heart, MessageSquareQuote, ArrowLeftRight, Star, Settings, PlusCircle, List, LayoutGrid } from "lucide-react";
import { ProfileListingsTab } from "@/components/ui/ProfileListingsTab";
import { FavorisClient } from "@/app/favoris/FavorisClient";
import { ManagedListing } from "@/components/ui/ManageListingCard";

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

interface AvisItem {
  note: number;
  commentaire: string | null;
  date_avis: string;
  acheteur: { nom: string; prenom: string | null; photo: string | null } | null;
}

interface TransactionItem {
  id: number;
  statut: string;
  montant: number | null;
  created_at: string;
  role: "acheteur" | "vendeur";
  annonce: { id: number; titre: string; imageUrl: string | null } | null;
  otherParty: { nom: string; prenom: string | null; photo: string | null } | null;
}

interface ProfilTabsClientProps {
  activeListings: ManagedListing[];
  suspendedListings: ManagedListing[];
  soldListings: ManagedListing[];
  favoriItems: FavoriItem[];
  avisItems: AvisItem[];
  transactionItems: TransactionItem[];
  counts: { annonces: number; favoris: number; avis: number; transactions: number };
  initialTab?: MainTab;
}

export type MainTab = "annonces" | "favoris" | "avis" | "transactions";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function timeAgo(date: string): string {
  const diff = Date.now() - new Date(date).getTime();
  const days = Math.floor(diff / 86400000);
  if (days === 0) return "Aujourd'hui";
  if (days === 1) return "Hier";
  if (days < 7) return `Il y a ${days}j`;
  return new Date(date).toLocaleDateString("fr-FR", { day: "numeric", month: "short", year: "numeric" });
}

function StarRow({ note }: { note: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <Star
          key={n}
          className={`h-3.5 w-3.5 ${n <= note ? "fill-[#FC7138] text-[#FC7138]" : "text-[#E3E2E2]"}`}
        />
      ))}
    </div>
  );
}

// ─── Component ───────────────────────────────────────────────────────────────

export function ProfilTabsClient({
  activeListings,
  suspendedListings,
  soldListings,
  favoriItems,
  avisItems,
  transactionItems,
  counts,
  initialTab = "annonces",
}: ProfilTabsClientProps) {
  const [activeTab, setActiveTab] = useState<MainTab>(initialTab);

  const tabs: { key: MainTab; label: string; icon: React.ElementType; count?: number }[] = [
    { key: "annonces",      label: "Mes annonces",  icon: Store,              count: counts.annonces },
    { key: "favoris",       label: "Favoris",        icon: Heart,              count: counts.favoris },
    { key: "avis",          label: "Avis reçus",     icon: MessageSquareQuote, count: counts.avis },
    { key: "transactions",  label: "Transactions",   icon: ArrowLeftRight,     count: counts.transactions },
  ];

  return (
    <div className="flex flex-col lg:flex-row gap-8 items-start">

      {/* ── Sidebar gauche ───────────────────────────────────────── */}
      <aside className="w-full lg:w-[260px] shrink-0">
        <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-4 shadow-[0_4px_20px_rgba(19,27,45,0.04)]">
          <h4 className="px-3 text-[11px] font-bold uppercase tracking-wider text-[#76777D] mb-2">
            Espace Vendeur
          </h4>
          <nav className="space-y-1">
            {tabs.map(({ key, label, icon: Icon, count }) => (
              <button
                key={key}
                type="button"
                onClick={() => setActiveTab(key)}
                className={`w-full flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-semibold transition-all text-left ${
                  activeTab === key
                    ? "bg-[#FFDBBF]/40 text-[#FC7138]"
                    : "text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C]"
                }`}
              >
                <span className="flex items-center gap-3">
                  <Icon className="h-4 w-4" />
                  {label}
                </span>
                {count !== undefined && count > 0 && (
                  <span className={`flex h-5 min-w-[20px] items-center justify-center rounded-full px-1.5 text-[11px] font-bold ${
                    activeTab === key
                      ? "bg-[#FC7138] text-white"
                      : "bg-[#F4F3F3] text-[#76777D]"
                  }`}>
                    {count}
                  </span>
                )}
              </button>
            ))}
          </nav>

          <div className="mt-4 border-t border-[#F4F3F3]">
            <h4 className="px-3 pt-4 text-[11px] font-bold uppercase tracking-wider text-[#76777D] mb-2">
              Mon Compte
            </h4>
            <nav className="space-y-1">
              <a
                href="/parametres"
                className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C] transition-all"
              >
                <Settings className="h-4 w-4" />
                Paramètres
              </a>
            </nav>
          </div>

          <div className="mt-4 pt-4 border-t border-[#F4F3F3]">
            <a
              href="/annonces/creer"
              className="flex items-center justify-center gap-2 rounded-full bg-[#FC7138] px-4 py-3 text-sm font-bold text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] transition-all"
            >
              <PlusCircle className="h-4 w-4" />
              Publier une annonce
            </a>
          </div>
        </div>
      </aside>

      {/* ── Contenu droite ───────────────────────────────────────── */}
      <div className="flex-1 w-full min-w-0">
        {activeTab === "annonces" && (
          <ProfileListingsTab
            active={activeListings}
            suspended={suspendedListings}
            sold={soldListings}
          />
        )}

        {activeTab === "favoris" && (
          <FavorisClient items={favoriItems} />
        )}

        {activeTab === "avis" && (
          <AvisTab items={avisItems} />
        )}

        {activeTab === "transactions" && (
          <TransactionsTab items={transactionItems} />
        )}
      </div>
    </div>
  );
}

// ─── Tab Avis ────────────────────────────────────────────────────────────────

function AvisTab({ items }: { items: AvisItem[] }) {
  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#F4F3F3]">
          <MessageSquareQuote className="h-7 w-7 text-[#E3E2E2]" strokeWidth={1.5} />
        </div>
        <h3 className="text-base font-bold text-[#131B2D]">Aucun avis pour l&apos;instant</h3>
        <p className="max-w-xs text-xs text-[#565E73]">
          Les avis apparaîtront ici après chaque vente confirmée.
        </p>
      </div>
    );
  }

  const noteMoyenne = Math.round((items.reduce((s, a) => s + a.note, 0) / items.length) * 10) / 10;

  return (
    <div className="space-y-5">
      {/* Récap */}
      <div className="flex items-center gap-4 rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-sm">
        <div className="flex flex-col items-center gap-1">
          <span className="text-4xl font-black text-[#131B2D]">{noteMoyenne.toFixed(1)}</span>
          <StarRow note={Math.round(noteMoyenne)} />
          <span className="text-xs text-[#76777D]">{items.length} avis</span>
        </div>
        <div className="flex-1 space-y-1.5 pl-4 border-l border-[#F4F3F3]">
          {[5, 4, 3, 2, 1].map((n) => {
            const count = items.filter((a) => a.note === n).length;
            const pct = Math.round((count / items.length) * 100);
            return (
              <div key={n} className="flex items-center gap-2 text-xs">
                <span className="w-4 text-right text-[#76777D] font-semibold">{n}</span>
                <Star className="h-3 w-3 fill-[#FC7138] text-[#FC7138] shrink-0" />
                <div className="flex-1 h-1.5 rounded-full bg-[#F4F3F3] overflow-hidden">
                  <div
                    className="h-full rounded-full bg-[#FC7138] transition-all"
                    style={{ width: `${pct}%` }}
                  />
                </div>
                <span className="w-8 text-[#76777D]">{count}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Liste avis */}
      <div className="space-y-4">
        {items.map((avis, i) => {
          const acheteurNom = avis.acheteur
            ? `${avis.acheteur.prenom ?? ""} ${avis.acheteur.nom}`.trim()
            : "Acheteur";
          const initiale = acheteurNom[0]?.toUpperCase() ?? "A";
          return (
            <div
              key={i}
              className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-[0_2px_12px_rgba(19,27,45,0.04)]"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="relative h-10 w-10 shrink-0 rounded-full overflow-hidden bg-[#FFDBBF] flex items-center justify-center">
                    {avis.acheteur?.photo ? (
                      <Image src={avis.acheteur.photo} alt={acheteurNom} fill className="object-cover" />
                    ) : (
                      <span className="text-sm font-bold text-[#FC7138]">{initiale}</span>
                    )}
                  </div>
                  <div>
                    <p className="text-sm font-bold text-[#131B2D]">{acheteurNom}</p>
                    <StarRow note={avis.note} />
                  </div>
                </div>
                <span className="text-xs text-[#76777D] shrink-0">{timeAgo(avis.date_avis)}</span>
              </div>
              {avis.commentaire && (
                <p className="mt-3 text-sm text-[#565E73] leading-relaxed pl-[52px]">
                  {avis.commentaire}
                </p>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── Tab Transactions ─────────────────────────────────────────────────────────

type TxFilter = "all" | "en_attente" | "en_cours" | "completee" | "annulee";

const STATUT_CONFIG: Record<string, { label: string; bg: string; text: string; dot: string }> = {
  en_attente: { label: "En attente",  bg: "bg-[#FFF7F4]",  text: "text-[#FC7138]", dot: "bg-[#FC7138]" },
  en_cours:   { label: "En cours",    bg: "bg-[#EFF6FF]",  text: "text-[#2563EB]", dot: "bg-[#2563EB]" },
  completee:  { label: "Complétée",   bg: "bg-[#E8F8F2]",  text: "text-[#00966B]", dot: "bg-[#00966B]" },
  annulee:    { label: "Annulée",     bg: "bg-[#FFF0F0]",  text: "text-[#BA1A1A]", dot: "bg-[#BA1A1A]" },
};

const PLACEHOLDER_TX = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=200&auto=format&fit=crop";

const TX_PAGE_SIZE = 5;

function TransactionsTab({ items }: { items: TransactionItem[] }) {
  const [filter, setFilter] = useState<TxFilter>("all");
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");
  const [visibleCount, setVisibleCount] = useState(TX_PAGE_SIZE);

  const filtered = filter === "all" ? items : items.filter((t) => t.statut === filter);
  const visible = filtered.slice(0, visibleCount);
  const hasMore = visibleCount < filtered.length;

  const totalMontantVendeur = items
    .filter((t) => t.role === "vendeur" && t.statut === "completee" && t.montant)
    .reduce((s, t) => s + (t.montant ?? 0), 0);

  const completees = items.filter((t) => t.statut === "completee").length;
  const enAttente  = items.filter((t) => t.statut === "en_attente").length;

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#F4F3F3]">
          <ArrowLeftRight className="h-7 w-7 text-[#E3E2E2]" strokeWidth={1.5} />
        </div>
        <h3 className="text-base font-bold text-[#131B2D]">Aucune transaction</h3>
        <p className="max-w-xs text-xs text-[#565E73]">
          Vos achats et ventes apparaîtront ici une fois validés.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-5">

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-4 shadow-sm">
          <p className="text-2xl font-black text-[#131B2D]">{items.length}</p>
          <p className="text-xs font-semibold text-[#565E73] mt-0.5">Total</p>
        </div>
        <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-4 shadow-sm">
          <p className="text-2xl font-black text-[#00966B]">{completees}</p>
          <p className="text-xs font-semibold text-[#565E73] mt-0.5">Complétées</p>
        </div>
        <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-4 shadow-sm">
          <p className="text-2xl font-black text-[#FC7138]">{enAttente}</p>
          <p className="text-xs font-semibold text-[#565E73] mt-0.5">En attente</p>
        </div>
      </div>

      {totalMontantVendeur > 0 && (
        <div className="flex items-center justify-between rounded-2xl bg-[#E8F8F2] border border-[#00966B]/20 px-5 py-3.5">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[#00966B] text-white shrink-0">
              <ArrowLeftRight className="h-4 w-4" />
            </div>
            <div>
              <p className="text-xs font-bold text-[#131B2D]">Revenus des ventes complétées</p>
              <p className="text-[11px] text-[#565E73]">Montant total encaissé en tant que vendeur</p>
            </div>
          </div>
          <p className="text-lg font-black text-[#00966B] shrink-0">
            {totalMontantVendeur.toLocaleString("fr-FR")} FCFA
          </p>
        </div>
      )}

      {/* Filtres statut + toggle vue */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-2">
          {(["all", "en_attente", "en_cours", "completee", "annulee"] as TxFilter[]).map((s) => {
            const cfg = s === "all" ? null : STATUT_CONFIG[s];
            const count = s === "all" ? items.length : items.filter((t) => t.statut === s).length;
            return (
              <button
                key={s}
                type="button"
                onClick={() => { setFilter(s); setVisibleCount(TX_PAGE_SIZE); }}
                className={`rounded-full px-3.5 py-1.5 text-xs font-bold transition-all ${
                  filter === s
                    ? "bg-[#131B2D] text-white shadow-sm"
                    : "bg-[#F4F3F3] text-[#565E73] hover:bg-[#E3E2E2]"
                }`}
              >
                {cfg ? cfg.label : "Toutes"}
                <span className={`ml-1.5 ${filter === s ? "text-white/70" : "text-[#76777D]"}`}>
                  ({count})
                </span>
              </button>
            );
          })}
        </div>

        {/* Toggle liste / cartes */}
        <div className="flex items-center rounded-xl border border-[#E3E2E2] bg-white p-0.5 shadow-sm shrink-0">
          <button
            type="button"
            onClick={() => setViewMode("list")}
            className={`flex h-8 w-8 items-center justify-center rounded-lg transition-colors ${viewMode === "list" ? "bg-[#F4F3F3] text-[#131B2D]" : "text-[#76777D] hover:text-[#131B2D]"}`}
            aria-label="Vue liste"
          >
            <List className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={() => setViewMode("grid")}
            className={`flex h-8 w-8 items-center justify-center rounded-lg transition-colors ${viewMode === "grid" ? "bg-[#F4F3F3] text-[#131B2D]" : "text-[#76777D] hover:text-[#131B2D]"}`}
            aria-label="Vue cartes"
          >
            <LayoutGrid className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Contenu */}
      {filtered.length === 0 ? (
        <div className="rounded-2xl border border-[#E3E2E2] bg-white p-10 text-center">
          <p className="text-sm font-bold text-[#131B2D]">Aucune transaction dans cette catégorie.</p>
        </div>
      ) : viewMode === "list" ? (
        /* ── Vue liste ── */
        <div className="space-y-3">
          {visible.map((tx) => {
            const cfg = STATUT_CONFIG[tx.statut] ?? STATUT_CONFIG["en_attente"];
            const otherName = tx.otherParty
              ? `${tx.otherParty.prenom ?? ""} ${tx.otherParty.nom}`.trim()
              : "Utilisateur";
            const initiale = otherName[0]?.toUpperCase() ?? "?";
            return (
              <div
                key={tx.id}
                className="flex items-center gap-4 rounded-2xl border border-[#E3E2E2]/60 bg-white p-4 shadow-[0_2px_12px_rgba(19,27,45,0.04)] hover:shadow-[0_4px_20px_rgba(19,27,45,0.08)] transition-shadow"
              >
                <div className="relative h-14 w-14 shrink-0 rounded-xl overflow-hidden bg-[#F4F3F3]">
                  <Image src={tx.annonce?.imageUrl ?? PLACEHOLDER_TX} alt={tx.annonce?.titre ?? "Annonce"} fill className="object-cover" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-bold text-[#131B2D]">
                        {tx.annonce?.titre ?? "Annonce supprimée"}
                      </p>
                      <div className="mt-0.5 flex items-center gap-2">
                        <div className="relative h-5 w-5 shrink-0 rounded-full overflow-hidden bg-[#FFDBBF] flex items-center justify-center">
                          {tx.otherParty?.photo
                            ? <Image src={tx.otherParty.photo} alt={otherName} fill className="object-cover" />
                            : <span className="text-[9px] font-bold text-[#FC7138]">{initiale}</span>
                          }
                        </div>
                        <span className="text-xs text-[#565E73]">
                          {tx.role === "acheteur" ? "Vendu par" : "Acheté par"}{" "}
                          <span className="font-semibold text-[#131B2D]">{otherName}</span>
                        </span>
                      </div>
                    </div>
                    <div className="shrink-0 text-right space-y-1">
                      {tx.montant && (
                        <p className="text-base font-black text-[#131B2D] leading-none">
                          {tx.montant.toLocaleString("fr-FR")} F
                        </p>
                      )}
                      <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-bold ${cfg.bg} ${cfg.text}`}>
                        <span className={`h-1.5 w-1.5 rounded-full ${cfg.dot}`} />
                        {cfg.label}
                      </span>
                    </div>
                  </div>
                  <div className="mt-1.5 flex items-center gap-3">
                    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide ${tx.role === "vendeur" ? "bg-[#FFF7F4] text-[#FC7138]" : "bg-[#EFF6FF] text-[#2563EB]"}`}>
                      {tx.role === "vendeur" ? "Vendeur" : "Acheteur"}
                    </span>
                    <span className="text-[11px] text-[#76777D]">{timeAgo(tx.created_at)} · #{tx.id}</span>
                    {tx.annonce && (
                      <a href={`/annonces/${tx.annonce.id}`} className="text-[11px] font-bold text-[#FC7138] hover:underline">
                        Voir l&apos;annonce
                      </a>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* ── Vue cartes ── */
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          {visible.map((tx) => {
            const cfg = STATUT_CONFIG[tx.statut] ?? STATUT_CONFIG["en_attente"];
            const otherName = tx.otherParty
              ? `${tx.otherParty.prenom ?? ""} ${tx.otherParty.nom}`.trim()
              : "Utilisateur";
            const initiale = otherName[0]?.toUpperCase() ?? "?";
            return (
              <div
                key={tx.id}
                className="flex flex-col rounded-2xl border border-[#E3E2E2]/60 bg-white overflow-hidden shadow-[0_4px_20px_rgba(19,27,45,0.04)] hover:shadow-[0_8px_28px_rgba(19,27,45,0.08)] transition-all hover:-translate-y-0.5"
              >
                {/* Image */}
                <div className="relative aspect-[16/9] w-full bg-[#F4F3F3] overflow-hidden">
                  <Image src={tx.annonce?.imageUrl ?? PLACEHOLDER_TX} alt={tx.annonce?.titre ?? "Annonce"} fill className="object-cover" />
                  <span className={`absolute top-3 left-3 inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-bold shadow-sm ${cfg.bg} ${cfg.text}`}>
                    <span className={`h-1.5 w-1.5 rounded-full ${cfg.dot}`} />
                    {cfg.label}
                  </span>
                  <span className={`absolute top-3 right-3 rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide ${tx.role === "vendeur" ? "bg-[#FC7138] text-white" : "bg-[#2563EB] text-white"}`}>
                    {tx.role === "vendeur" ? "Vendeur" : "Acheteur"}
                  </span>
                </div>

                {/* Contenu */}
                <div className="flex flex-1 flex-col p-4 gap-3">
                  <div>
                    <p className="line-clamp-1 text-sm font-bold text-[#131B2D]">
                      {tx.annonce?.titre ?? "Annonce supprimée"}
                    </p>
                    {tx.montant ? (
                      <p className="mt-0.5 text-xl font-black text-[#131B2D] tracking-tight">
                        {tx.montant.toLocaleString("fr-FR")} <span className="text-sm font-bold text-[#76777D]">FCFA</span>
                      </p>
                    ) : (
                      <p className="mt-0.5 text-sm font-semibold text-[#76777D]">Montant non renseigné</p>
                    )}
                  </div>

                  <div className="flex items-center gap-2 border-t border-[#F4F3F3] pt-3">
                    <div className="relative h-7 w-7 shrink-0 rounded-full overflow-hidden bg-[#FFDBBF] flex items-center justify-center">
                      {tx.otherParty?.photo
                        ? <Image src={tx.otherParty.photo} alt={otherName} fill className="object-cover" />
                        : <span className="text-[9px] font-bold text-[#FC7138]">{initiale}</span>
                      }
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-xs font-bold text-[#131B2D]">{otherName}</p>
                      <p className="text-[11px] text-[#76777D]">{tx.role === "acheteur" ? "Vendeur" : "Acheteur"} · {timeAgo(tx.created_at)}</p>
                    </div>
                    {tx.annonce && (
                      <a href={`/annonces/${tx.annonce.id}`} className="shrink-0 rounded-full bg-[#F4F3F3] px-3 py-1.5 text-[11px] font-bold text-[#131B2D] hover:bg-[#E3E2E2] transition-colors">
                        Voir
                      </a>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Voir plus */}
      {hasMore && (
        <div className="flex flex-col items-center gap-2 pt-2">
          <button
            type="button"
            onClick={() => setVisibleCount((n) => n + TX_PAGE_SIZE)}
            className="rounded-full border border-[#E3E2E2] bg-white px-8 py-3 text-sm font-bold text-[#131B2D] shadow-sm hover:bg-[#F4F3F3] hover:border-[#131B2D] transition-all"
          >
            Voir plus
            <span className="ml-2 text-[#76777D] font-normal text-xs">
              ({filtered.length - visibleCount} restantes)
            </span>
          </button>
        </div>
      )}
    </div>
  );
}
