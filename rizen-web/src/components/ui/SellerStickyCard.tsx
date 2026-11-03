"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ShoppingBag,
  MessageSquare,
  TrendingDown,
  ShieldCheck,
  RotateCcw,
  Zap,
  CheckCircle2,
  AlertTriangle,
  Flag,
  ChevronRight,
  Calendar,
  Package,
  Loader2,
  Pencil,
  CheckSquare,
  Trash2,
  X,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

export interface SellerInfo {
  id: string;
  name: string;
  avatar: string | null;
  rating: number;
  reviewCount: number;
  memberSince: string;
  activeListingsCount: number;
  verified: boolean;
  telephone: string | null;
}

interface SellerStickyCardProps {
  price: number;
  isNegotiable: boolean;
  listingId: string;
  annonceId: string;
  titre?: string;
  prixNegocie?: number | null;
  currentUserId?: string | null;
  seller: SellerInfo;
  statut?: string;
  onReport?: () => void;
}

export function SellerStickyCard({
  price,
  isNegotiable,
  listingId,
  annonceId,
  titre,
  prixNegocie,
  currentUserId,
  seller,
  statut = "active",
  onReport,
}: SellerStickyCardProps) {
  const router = useRouter();
  const [loadingMsg, setLoadingMsg] = useState(false);
  const [loadingStatus, setLoadingStatus] = useState(false);
  const [loadingDelete, setLoadingDelete] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [currentStatut, setCurrentStatut] = useState(statut);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // ── Négociation modal ──────────────────────────────────────────────────────
  const [showNegModal, setShowNegModal] = useState(false);
  const [negChip, setNegChip] = useState<number | null>(null);
  const [negCustomPrix, setNegCustomPrix] = useState("");
  const [negMessage, setNegMessage] = useState("");
  const [negLoading, setNegLoading] = useState(false);
  const [negError, setNegError] = useState<string | null>(null);

  const chips = [
    { label: "-5%",  value: Math.round(price * 0.95) },
    { label: "-15%", value: Math.round(price * 0.85) },
    { label: "-25%", value: Math.round(price * 0.75) },
  ];

  const negPrixEffectif = negChip !== null
    ? negChip
    : negCustomPrix
    ? Number(negCustomPrix.replace(/\s/g, ""))
    : null;

  const negEconomie =
    negPrixEffectif !== null && negPrixEffectif > 0 && negPrixEffectif < price
      ? price - negPrixEffectif
      : null;

  const openNegModal = async () => {
    if (!currentUserId) {
      router.push(`/auth/gate?redirect=/annonces/${annonceId}`);
      return;
    }

    // Vérifier si une négociation est déjà en cours ou acceptée
    const { data: existing } = await supabase
      .from("negociations")
      .select("id, statut")
      .eq("annonce_id", Number(annonceId))
      .eq("acheteur_id", currentUserId)
      .in("statut", ["en_attente", "acceptee"])
      .maybeSingle();

    if (existing) {
      setError(
        existing.statut === "acceptee"
          ? "Vous avez déjà un accord de prix sur cet article."
          : "Vous avez déjà une négociation en cours pour cet article."
      );
      return;
    }

    setNegChip(null);
    setNegCustomPrix("");
    setNegMessage("");
    setNegError(null);
    setShowNegModal(true);
  };

  const handleNegocier = async () => {
    if (!negPrixEffectif || negPrixEffectif <= 0) {
      setNegError("Entrez un prix de négociation.");
      return;
    }
    if (negPrixEffectif >= price) {
      setNegError("Le prix proposé doit être inférieur au prix affiché.");
      return;
    }
    if (!currentUserId) return;

    setNegLoading(true);
    setNegError(null);

    try {
      // 1. Créer ou récupérer la conversation
      const { data: convId, error: convErr } = await supabase.rpc("creer_conversation", {
        p_annonce_id: Number(annonceId),
        p_vendeur_id: seller.id,
      });
      if (convErr || !convId) throw new Error("Impossible de créer la conversation.");

      // 2. Insérer la négociation
      const { data: neg, error: negErr } = await supabase
        .from("negociations")
        .insert({
          annonce_id: Number(annonceId),
          acheteur_id: currentUserId,
          vendeur_id: seller.id,
          prix_propose: negPrixEffectif,
          conversation_id: convId,
          message: negMessage.trim() || null,
          statut: "en_attente",
        })
        .select("id")
        .maybeSingle();
      if (negErr || !neg) throw new Error("Impossible d'enregistrer la négociation.");

      // 3. Envoyer le message de type négociation dans la conversation
      await supabase.from("messages").insert({
        conversation_id: convId,
        sender_id: currentUserId,
        contenu: `Proposition de prix : ${negPrixEffectif.toLocaleString("fr-FR")} FCFA`,
        type: "negociation",
        negociation_id: neg.id,
      });

      // 4. Rediriger vers la conversation
      router.push(`/messages?conv=${convId}`);
    } catch (e: unknown) {
      setNegError(e instanceof Error ? e.message : "Une erreur est survenue.");
      setNegLoading(false);
    }
  };

  const formattedPrice = `${price.toLocaleString("fr-FR")} FCFA`;
  const isOwnListing = currentUserId === seller.id;

  // ── Mise à jour statut ─────────────────────────────────────────────────
  const updateStatut = async (newStatut: string, label: string) => {
    setLoadingStatus(true);
    setError(null);
    setSuccessMsg(null);
    try {
      const { error: err } = await supabase
        .from("annonces")
        .update({ statut: newStatut })
        .eq("id", Number(annonceId));
      if (err) throw err;
      setCurrentStatut(newStatut);
      setSuccessMsg(label);
      if (newStatut === "vendue") {
        setTimeout(() => router.push("/profil"), 1500);
      }
    } catch {
      setError("Impossible de mettre à jour le statut. Réessayez.");
    } finally {
      setLoadingStatus(false);
    }
  };

  // ── Supprimer ─────────────────────────────────────────────────────────
  const handleDelete = async () => {
    setLoadingDelete(true);
    setError(null);
    try {
      const { error: err } = await supabase
        .from("annonces")
        .delete()
        .eq("id", Number(annonceId));
      if (err) throw err;
      router.push("/profil");
    } catch {
      setError("Impossible de supprimer l'annonce. Réessayez.");
      setLoadingDelete(false);
      setConfirmDelete(false);
    }
  };

  // ── Acheter ────────────────────────────────────────────────────────────
  const handleAcheter = () => {
    if (!currentUserId) {
      router.push(`/auth/gate?redirect=/annonces/${annonceId}`);
      return;
    }
    if (isOwnListing) {
      setError("Vous ne pouvez pas acheter votre propre annonce.");
      return;
    }
    router.push(
      `/paiement?annonce=${annonceId}&vendeur=${seller.id}&montant=${price}`
    );
  };

  // ── Message ────────────────────────────────────────────────────────────
  const handleMessage = async () => {
    if (!currentUserId) {
      router.push(`/auth/gate?redirect=/annonces/${annonceId}`);
      return;
    }
    if (isOwnListing) {
      setError("Vous ne pouvez pas vous envoyer un message à vous-même.");
      return;
    }
    setError(null);
    setLoadingMsg(true);
    try {
      const convId = await supabase.rpc("creer_conversation", {
        p_annonce_id: Number(annonceId),
        p_vendeur_id: seller.id,
      });
      if (convId.error) throw convId.error;
      router.push(`/messages?conv=${convId.data}`);
    } catch {
      setError("Impossible d'ouvrir la conversation. Réessayez.");
    } finally {
      setLoadingMsg(false);
    }
  };

  return (
    <div className="sticky top-[88px] space-y-4">
      <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.06)]">
        {/* Prix */}
        <div>
          <span className="text-xs font-semibold uppercase tracking-wider text-[#565E73]">
            Prix de vente
          </span>
          {prixNegocie ? (
            <div className="mt-1 space-y-0.5">
              <p className="text-sm font-semibold text-[#76777D] line-through">
                {formattedPrice}
              </p>
              <div className="flex items-baseline gap-2">
                <h2 className="text-3xl font-extrabold tracking-tight text-[#131B2D]">
                  {prixNegocie.toLocaleString("fr-FR")} FCFA
                </h2>
                <span className="rounded-full bg-[#E8F5EE] px-3 py-1 text-xs font-bold text-[#00966B] shrink-0">
                  Prix négocié
                </span>
              </div>
            </div>
          ) : (
            <div className="mt-1 flex items-baseline justify-between gap-2">
              <h2 className="text-3xl font-extrabold tracking-tight text-[#131B2D]">
                {formattedPrice}
              </h2>
              {isNegotiable && (
                <span className="rounded-full bg-[#E8F5EE] px-3 py-1 text-xs font-bold text-[#00966B] shrink-0">
                  Négociable
                </span>
              )}
            </div>
          )}
        </div>

        {/* Feedback */}
        {error && (
          <p className="mt-3 rounded-xl bg-red-50 px-3 py-2 text-xs font-medium text-[#BA1A1A]">
            {error}
          </p>
        )}
        {successMsg && (
          <p className="mt-3 rounded-xl bg-[#E8F5EE] px-3 py-2 text-xs font-medium text-[#00966B]">
            {successMsg}
          </p>
        )}

        {/* CTAs — propriétaire */}
        {isOwnListing ? (
          <div className="mt-6 space-y-3">
            <div className="rounded-xl bg-[#F4F3F3] px-4 py-2.5 text-center">
              <p className="text-xs font-bold text-[#131B2D]">Votre annonce</p>
              <p className="text-[11px] text-[#565E73] mt-0.5">
                Statut : <span className={`font-semibold ${currentStatut === "active" ? "text-[#00966B]" : currentStatut === "vendue" ? "text-[#565E73]" : "text-[#FC7138]"}`}>
                  {currentStatut === "active" ? "Active" : currentStatut === "vendue" ? "Vendue" : "Suspendue"}
                </span>
              </p>
            </div>

            <Link
              href={`/annonces/${annonceId}/modifier`}
              className="flex h-[52px] w-full items-center justify-center gap-2 rounded-full bg-[#131B2D] px-6 text-sm font-bold text-white transition-all hover:bg-[#1e2d4a] active:scale-[0.99]"
            >
              <Pencil className="h-4 w-4" />
              Modifier l&apos;annonce
            </Link>

            {currentStatut !== "vendue" && (
              <button
                type="button"
                onClick={() => updateStatut("vendue", "Annonce marquée comme vendue")}
                disabled={loadingStatus}
                className="flex h-[48px] w-full items-center justify-center gap-2 rounded-full bg-[#00966B] px-6 text-sm font-bold text-white transition-all hover:bg-[#007a57] active:scale-[0.99] disabled:opacity-60"
              >
                {loadingStatus ? <Loader2 className="h-4 w-4 animate-spin" /> : <CheckSquare className="h-4 w-4" />}
                Marquer comme vendue
              </button>
            )}

            {/* Supprimer — confirmation inline */}
            {!confirmDelete ? (
              <button
                type="button"
                onClick={() => setConfirmDelete(true)}
                className="flex h-[44px] w-full items-center justify-center gap-2 rounded-full border border-red-200 bg-white px-6 text-sm font-semibold text-red-500 transition-all hover:bg-red-50 active:scale-[0.99]"
              >
                <Trash2 className="h-4 w-4" />
                Supprimer l&apos;annonce
              </button>
            ) : (
              <div className="rounded-xl border border-red-200 bg-red-50 p-3.5 space-y-2.5">
                <p className="text-xs font-semibold text-red-700 text-center">
                  Confirmer la suppression ? Cette action est irréversible.
                </p>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setConfirmDelete(false)}
                    disabled={loadingDelete}
                    className="flex h-9 flex-1 items-center justify-center gap-1.5 rounded-full border border-[#E3E2E2] bg-white text-xs font-bold text-[#565E73] hover:bg-[#F4F3F3] transition-all"
                  >
                    <X className="h-3.5 w-3.5" />
                    Annuler
                  </button>
                  <button
                    type="button"
                    onClick={handleDelete}
                    disabled={loadingDelete}
                    className="flex h-9 flex-1 items-center justify-center gap-1.5 rounded-full bg-red-500 text-xs font-bold text-white hover:bg-red-600 transition-all disabled:opacity-60"
                  >
                    {loadingDelete ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Trash2 className="h-3.5 w-3.5" />}
                    Supprimer
                  </button>
                </div>
              </div>
            )}

          </div>
        ) : (
          /* CTAs — acheteur */
          <div className="mt-6 space-y-3">
            <button
              type="button"
              onClick={handleAcheter}
              className="flex h-[52px] w-full items-center justify-center gap-2 rounded-full bg-[#FC7138] px-6 text-sm font-bold text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)] transition-all hover:bg-[#e05f29] active:scale-[0.99]"
            >
              <ShoppingBag className="h-4 w-4" />
              Acheter
            </button>

            <button
              type="button"
              onClick={openNegModal}
              className="flex h-[48px] w-full items-center justify-center gap-2 rounded-full border border-[#131B2D] bg-white px-6 text-sm font-bold text-[#131B2D] transition-all hover:bg-[#F4F3F3] active:scale-[0.99]"
            >
              <TrendingDown className="h-4 w-4" />
              Négocier le prix
            </button>

            <button
              type="button"
              onClick={handleMessage}
              disabled={loadingMsg}
              className="flex h-[48px] w-full items-center justify-center gap-2 rounded-full border border-[#E3E2E2] bg-white px-6 text-sm font-semibold text-[#565E73] transition-all hover:bg-[#F4F3F3] active:scale-[0.99] disabled:opacity-50"
            >
              {loadingMsg ? <Loader2 className="h-4 w-4 animate-spin" /> : <MessageSquare className="h-4 w-4" />}
              {loadingMsg ? "Ouverture..." : "Envoyer un message"}
            </button>
          </div>
        )}

        {/* Piliers de confiance */}
        <div className="mt-6 grid grid-cols-3 gap-2 border-y border-[#F4F3F3] py-4 text-center">
          <div className="flex flex-col items-center gap-1">
            <ShieldCheck className="h-4 w-4 text-[#00966B]" />
            <span className="text-[11px] font-semibold text-[#1A1C1C]">Identité vérifiée</span>
          </div>
          <div className="flex flex-col items-center gap-1">
            <RotateCcw className="h-4 w-4 text-[#00966B]" />
            <span className="text-[11px] font-semibold text-[#1A1C1C]">Remise directe</span>
          </div>
          <div className="flex flex-col items-center gap-1">
            <Zap className="h-4 w-4 text-[#00966B]" />
            <span className="text-[11px] font-semibold text-[#1A1C1C]">Réponse rapide</span>
          </div>
        </div>

        {/* Profil vendeur */}
        <div className="mt-6">
          <div className="flex items-center gap-3">
            <div className="relative h-12 w-12 shrink-0 overflow-hidden rounded-full ring-2 ring-[#00966B] bg-[#FFDBBF] flex items-center justify-center">
              {seller.avatar ? (
                <Image src={seller.avatar} alt={seller.name} fill className="object-cover" />
              ) : (
                <span className="text-[#FC7138] font-bold">{seller.name[0]?.toUpperCase()}</span>
              )}
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <h3 className="truncate text-sm font-bold text-[#1A1C1C]">{seller.name}</h3>
                {seller.verified && (
                  <CheckCircle2 className="h-4 w-4 shrink-0 fill-[#00966B] text-white" />
                )}
              </div>
              {seller.reviewCount > 0 ? (
                <div className="flex items-center gap-1 text-xs text-[#565E73]">
                  <span className="font-bold text-[#FC7138]">★ {seller.rating.toFixed(1)}</span>
                  <span>·</span>
                  <span>{seller.reviewCount} avis</span>
                </div>
              ) : (
                <span className="text-xs text-[#76777D]">Nouveau vendeur</span>
              )}
            </div>
          </div>

          <ul className="mt-4 space-y-2 text-xs text-[#565E73]">
            <li className="flex items-center gap-2">
              <Calendar className="h-3.5 w-3.5 shrink-0 text-gray-400" />
              <span>Membre depuis {seller.memberSince}</span>
            </li>
            {seller.activeListingsCount > 0 && (
              <li className="flex items-center gap-2">
                <Package className="h-3.5 w-3.5 shrink-0 text-gray-400" />
                <span>
                  {seller.activeListingsCount} annonce{seller.activeListingsCount > 1 ? "s" : ""} active{seller.activeListingsCount > 1 ? "s" : ""}
                </span>
              </li>
            )}
          </ul>

          <Link
            href={`/profil/${seller.id}`}
            className="mt-4 flex items-center justify-center gap-1 text-xs font-bold text-[#FC7138] hover:underline"
          >
            Voir le profil complet
            <ChevronRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        {/* Alerte sécurité */}
        <div className="mt-6 rounded-xl bg-[#FFF7F4] border border-[#FC7138]/20 p-3.5">
          <div className="flex items-start gap-2.5">
            <AlertTriangle className="h-4 w-4 shrink-0 text-[#FC7138] mt-0.5" />
            <div>
              <h4 className="text-xs font-bold text-[#FC7138]">Conseil de sécurité Rizen</h4>
              <p className="mt-0.5 text-[11px] leading-relaxed text-[#565E73]">
                Ne payez jamais d&apos;avance avant d&apos;avoir inspecté le produit en personne dans un lieu public sécurisé à Dakar.
              </p>
            </div>
          </div>
        </div>

        {/* Signaler */}
        {!isOwnListing && (
          <div className="mt-4">
            <button
              type="button"
              onClick={onReport}
              className="flex w-full items-center justify-center gap-2 rounded-xl border border-[#E3E2E2] bg-white px-4 py-2.5 text-xs font-semibold text-[#565E73] transition-all hover:border-red-200 hover:bg-red-50 hover:text-[#BA1A1A]"
            >
              <Flag className="h-3.5 w-3.5" />
              Signaler cette annonce
            </button>
          </div>
        )}
      </div>

      {/* ── Modale Négociation ─────────────────────────────────────────────────── */}
      {showNegModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 sm:p-0">
          {/* Backdrop */}
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => setShowNegModal(false)}
          />

          {/* Card */}
          <div className="relative z-10 w-full max-w-md max-h-[90vh] overflow-y-auto rounded-2xl bg-white shadow-2xl sm:rounded-2xl">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-[#F4F3F3] px-6 py-4">
              <div>
                <h2 className="text-base font-bold text-[#131B2D]">Faire une offre</h2>
                {titre && (
                  <p className="mt-0.5 text-xs text-[#565E73] line-clamp-1">{titre}</p>
                )}
              </div>
              <button
                type="button"
                onClick={() => setShowNegModal(false)}
                className="rounded-full p-1.5 hover:bg-[#F4F3F3] transition-colors"
              >
                <X className="h-4 w-4 text-[#565E73]" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-5">
              {/* Prix actuel */}
              <div className="rounded-xl bg-[#F4F3F3] px-4 py-3 text-center">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-[#565E73]">
                  Prix affiché
                </p>
                <p className="mt-0.5 text-xl font-extrabold text-[#131B2D]">
                  {price.toLocaleString("fr-FR")} FCFA
                </p>
              </div>

              {/* Chips rapides */}
              <div>
                <p className="mb-2 text-xs font-bold text-[#131B2D]">Réduction rapide</p>
                <div className="flex gap-2">
                  {chips.map((c) => (
                    <button
                      key={c.label}
                      type="button"
                      onClick={() => {
                        setNegChip(c.value);
                        setNegCustomPrix("");
                      }}
                      className={`flex-1 rounded-full border px-3 py-2 text-xs font-bold transition-all ${
                        negChip === c.value
                          ? "border-[#131B2D] bg-[#131B2D] text-white"
                          : "border-[#E3E2E2] bg-white text-[#131B2D] hover:border-[#131B2D]"
                      }`}
                    >
                      <span className="block">{c.label}</span>
                      <span className={`block text-[10px] font-normal mt-0.5 ${negChip === c.value ? "text-white/70" : "text-[#565E73]"}`}>
                        {c.value.toLocaleString("fr-FR")}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Prix libre */}
              <div>
                <label className="text-xs font-bold text-[#131B2D]" htmlFor="neg-prix">
                  Ou saisir un prix manuellement (FCFA)
                </label>
                <input
                  id="neg-prix"
                  type="number"
                  min={1}
                  max={price - 1}
                  value={negCustomPrix}
                  onChange={(e) => {
                    setNegCustomPrix(e.target.value);
                    setNegChip(null);
                  }}
                  placeholder={`Ex : ${Math.round(price * 0.9).toLocaleString("fr-FR")}`}
                  className="mt-1.5 h-11 w-full rounded-xl border border-[#E3E2E2] bg-white px-4 text-sm text-[#131B2D] placeholder:text-[#C4C4C4] focus:border-[#131B2D] focus:outline-none"
                />
              </div>

              {/* Indicateur d'économie */}
              {negEconomie !== null && (
                <div className="flex items-center gap-2 rounded-xl bg-[#E8F5EE] px-4 py-2.5">
                  <TrendingDown className="h-4 w-4 shrink-0 text-[#00966B]" />
                  <p className="text-xs font-semibold text-[#00966B]">
                    Vous économisez{" "}
                    <span className="font-extrabold">
                      {negEconomie.toLocaleString("fr-FR")} FCFA
                    </span>{" "}
                    (
                    {Math.round((negEconomie / price) * 100)}% de réduction)
                  </p>
                </div>
              )}
              {negPrixEffectif !== null && negPrixEffectif >= price && (
                <p className="rounded-xl bg-red-50 px-4 py-2.5 text-xs font-semibold text-[#BA1A1A]">
                  Le prix proposé doit être inférieur au prix affiché.
                </p>
              )}

              {/* Message optionnel */}
              <div>
                <label className="text-xs font-bold text-[#131B2D]" htmlFor="neg-msg">
                  Message au vendeur{" "}
                  <span className="font-normal text-[#76777D]">(optionnel)</span>
                </label>
                <textarea
                  id="neg-msg"
                  rows={2}
                  value={negMessage}
                  onChange={(e) => setNegMessage(e.target.value)}
                  placeholder="Ex : Je suis intéressé, disponible ce week-end…"
                  className="mt-1.5 w-full resize-none rounded-xl border border-[#E3E2E2] bg-white px-4 py-2.5 text-sm text-[#131B2D] placeholder:text-[#C4C4C4] focus:border-[#131B2D] focus:outline-none"
                />
              </div>

              {/* Erreur */}
              {negError && (
                <p className="rounded-xl bg-red-50 px-4 py-2.5 text-xs font-semibold text-[#BA1A1A]">
                  {negError}
                </p>
              )}

              {/* Actions */}
              <div className="flex gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setShowNegModal(false)}
                  disabled={negLoading}
                  className="flex h-11 flex-1 items-center justify-center rounded-full border border-[#E3E2E2] text-sm font-semibold text-[#565E73] hover:bg-[#F4F3F3] transition-all disabled:opacity-50"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={handleNegocier}
                  disabled={negLoading || !negPrixEffectif || negPrixEffectif <= 0 || negPrixEffectif >= price}
                  className="flex h-11 flex-1 items-center justify-center gap-2 rounded-full bg-[#131B2D] text-sm font-bold text-white transition-all hover:bg-[#1e2d4a] active:scale-[0.99] disabled:opacity-50"
                >
                  {negLoading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <TrendingDown className="h-4 w-4" />
                  )}
                  {negLoading ? "Envoi…" : "Envoyer l'offre"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
