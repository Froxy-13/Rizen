"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  CheckCircle2,
  XCircle,
  MessageSquare,
  ArrowLeft,
  Handshake,
  Star,
  MapPin,
  Tag,
  TrendingDown,
  ChevronRight,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

// ─── Types ────────────────────────────────────────────────────────────────────

interface ProfilData {
  id: string;
  nom: string;
  prenom: string | null;
  photo: string | null;
  noteMoyenne: number | null;
  nombreAvis: number;
  certifie: boolean;
}

interface Annonce {
  id: number;
  titre: string;
  prix_actuel: number;
  prix_initial: number;
  etat: string | null;
  ville: string | null;
  quartier: string | null;
  categorieNom: string | null;
  imageUrl: string;
}

interface HistoryItem {
  id: number;
  prix_propose: number;
  date_proposition: string;
  statut: string;
  message: string | null;
  isAcheteur: boolean;
  isCurrent: boolean;
}

interface NegociationClientProps {
  negId: number;
  statut: string;
  prixPropose: number;
  message: string | null;
  dateProposition: string;
  role: "acheteur" | "vendeur";
  currentUserId: string;
  annonce: Annonce | null;
  acheteur: ProfilData | null;
  vendeur: ProfilData | null;
  history: HistoryItem[];
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const STATUT = {
  en_attente: { label: "En attente",  bg: "bg-[#FFF7F4]",  text: "text-[#FC7138]", dot: "bg-[#FC7138]" },
  acceptee:   { label: "Acceptée",    bg: "bg-[#E8F8F2]",  text: "text-[#00966B]", dot: "bg-[#00966B]" },
  refusee:    { label: "Refusée",     bg: "bg-[#FFF0F0]",  text: "text-[#BA1A1A]", dot: "bg-[#BA1A1A]" },
  annulee:    { label: "Annulée",     bg: "bg-[#F4F3F3]",  text: "text-[#565E73]", dot: "bg-[#76777D]" },
};

function formatFCFA(n: number) {
  return `${n.toLocaleString("fr-FR")} FCFA`;
}

function dateShort(d: string) {
  return new Date(d).toLocaleDateString("fr-FR", { day: "numeric", month: "short", year: "numeric" });
}

// ─── Component ───────────────────────────────────────────────────────────────

export function NegociationClient({
  negId,
  statut: initialStatut,
  prixPropose,
  message,
  dateProposition,
  role,
  annonce,
  acheteur,
  vendeur,
  history,
}: NegociationClientProps) {
  const router = useRouter();
  const [statut, setStatut] = useState(initialStatut);
  const [loading, setLoading] = useState(false);
  const [counterMode, setCounterMode] = useState(false);
  const [counterPrice, setCounterPrice] = useState("");
  const [counterMsg, setCounterMsg] = useState("");

  const cfg = STATUT[statut as keyof typeof STATUT] ?? STATUT.en_attente;
  const isActive = statut === "en_attente";
  const otherParty = role === "acheteur" ? vendeur : acheteur;
  const otherPartyLabel = role === "acheteur" ? "Vendeur" : "Acheteur";
  const otherName = otherParty ? `${otherParty.prenom ?? ""} ${otherParty.nom}`.trim() : "Utilisateur";

  const savings = annonce ? annonce.prix_initial - prixPropose : 0;
  const savingsPct = annonce && annonce.prix_initial > 0
    ? Math.round((savings / annonce.prix_initial) * 100)
    : 0;

  // ── Actions ──────────────────────────────────────────────────────────────

  const handleAccept = async () => {
    setLoading(true);
    const { error } = await supabase
      .from("negociations")
      .update({ statut: "acceptee" })
      .eq("id", negId);
    if (!error) setStatut("acceptee");
    setLoading(false);
  };

  const handleRefuse = async () => {
    setLoading(true);
    const { error } = await supabase
      .from("negociations")
      .update({ statut: "refusee" })
      .eq("id", negId);
    if (!error) setStatut("refusee");
    setLoading(false);
  };

  const handleCounter = async () => {
    const price = parseInt(counterPrice.replace(/\s/g, ""), 10);
    if (!price || !annonce) return;
    setLoading(true);

    // Marquer l'offre actuelle comme dépassée
    await supabase.from("negociations").update({ statut: "annulee" }).eq("id", negId);

    // Créer la contre-offre (rôles inversés pour la proposition)
    const { data: newNeg } = await supabase
      .from("negociations")
      .insert({
        annonce_id: annonce.id,
        acheteur_id: acheteur?.id,
        vendeur_id: vendeur?.id,
        prix_propose: price,
        message: counterMsg || null,
        statut: "en_attente",
      })
      .select("id")
      .maybeSingle();

    setLoading(false);
    if (newNeg?.id) {
      router.push(`/negociations/${newNeg.id}`);
    } else {
      router.refresh();
    }
  };

  // ── Render ───────────────────────────────────────────────────────────────

  return (
    <main className="mx-auto max-w-[1100px] px-4 py-8 md:px-6 space-y-6">

      {/* Retour */}
      <Link href="/messages" className="inline-flex items-center gap-2 text-xs font-bold text-[#565E73] hover:text-[#131B2D] transition-colors">
        <ArrowLeft className="h-4 w-4" />
        Retour aux messages
      </Link>

      <div className="grid grid-cols-1 lg:grid-cols-[380px_1fr] gap-6">

        {/* ── Colonne gauche ──────────────────────────────────────── */}
        <div className="space-y-5">

          {/* Annonce */}
          {annonce && (
            <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white overflow-hidden shadow-[0_4px_20px_rgba(19,27,45,0.04)]">
              <div className="relative aspect-[16/10] w-full overflow-hidden bg-[#F4F3F3]">
                <Image src={annonce.imageUrl} alt={annonce.titre} fill className="object-cover" priority />
                {annonce.etat && (
                  <span className="absolute top-3 left-3 inline-flex items-center gap-1.5 rounded-full bg-white/95 backdrop-blur-sm px-3 py-1 text-xs font-bold text-[#131B2D] shadow-sm">
                    <span className="h-2 w-2 rounded-full bg-[#00966B]" />
                    {annonce.etat === "neuf" ? "Neuf" : annonce.etat === "tres_bon" ? "Très bon état" : annonce.etat === "bon" ? "Bon état" : "Correct"}
                  </span>
                )}
                {annonce.categorieNom && (
                  <span className="absolute top-3 right-3 rounded-full bg-[#131B2D]/80 backdrop-blur-sm px-3 py-1 text-xs font-semibold text-white">
                    {annonce.categorieNom}
                  </span>
                )}
                <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent p-4 text-white">
                  {annonce.ville && (
                    <p className="text-[10px] font-bold uppercase tracking-wider text-white/75 flex items-center gap-1">
                      <MapPin className="h-3 w-3 shrink-0" />
                      {[annonce.quartier, annonce.ville].filter(Boolean).join(", ")}
                    </p>
                  )}
                  <h2 className="text-base font-black tracking-tight mt-0.5 leading-snug">{annonce.titre}</h2>
                </div>
              </div>

              <div className="p-5 space-y-4">
                {/* Prix */}
                <div className="flex items-end justify-between gap-2">
                  <div>
                    <p className="text-[11px] font-semibold text-[#76777D]">Prix affiché</p>
                    <p className="text-sm font-bold text-[#565E73] line-through">{formatFCFA(annonce.prix_initial)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-[11px] font-bold uppercase tracking-wide text-[#76777D]">Offre en cours</p>
                    <p className="text-2xl font-black text-[#FC7138] tracking-tight">{formatFCFA(prixPropose)}</p>
                  </div>
                </div>

                {/* Écart */}
                {savings > 0 && (
                  <div className="flex items-center justify-between rounded-xl bg-[#E8F8F2] border border-[#00966B]/20 px-3.5 py-2.5">
                    <div className="flex items-center gap-2 text-xs font-bold text-[#131B2D]">
                      <Handshake className="h-4 w-4 text-[#00966B]" />
                      Écart de négociation
                    </div>
                    <span className="text-xs font-black text-[#00966B]">
                      -{formatFCFA(savings)} (-{savingsPct}%)
                    </span>
                  </div>
                )}

                <Link
                  href={`/annonces/${annonce.id}`}
                  className="flex items-center justify-center gap-2 rounded-full border border-[#E3E2E2] bg-[#FAF9F9] py-2.5 text-xs font-bold text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#131B2D] transition-colors"
                >
                  <Tag className="h-3.5 w-3.5" />
                  Voir l&apos;annonce complète
                  <ChevronRight className="h-3.5 w-3.5" />
                </Link>
              </div>
            </div>
          )}

          {/* Autre partie */}
          {otherParty && (
            <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-[0_4px_20px_rgba(19,27,45,0.04)] space-y-3">
              <p className="text-[11px] font-bold uppercase tracking-wider text-[#76777D]">{otherPartyLabel}</p>
              <div className="flex items-center gap-3.5">
                <div className="relative h-12 w-12 shrink-0 rounded-full overflow-hidden ring-2 ring-[#E3E2E2] bg-[#FFDBBF] flex items-center justify-center">
                  {otherParty.photo
                    ? <Image src={otherParty.photo} alt={otherName} fill className="object-cover" />
                    : <span className="text-sm font-bold text-[#FC7138]">{otherName[0]?.toUpperCase()}</span>
                  }
                  {otherParty.certifie && (
                    <span className="absolute bottom-0 right-0 flex h-4 w-4 items-center justify-center rounded-full bg-[#00966B] ring-1 ring-white">
                      <CheckCircle2 className="h-2.5 w-2.5 text-white" />
                    </span>
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-bold text-[#131B2D] truncate">{otherName}</p>
                  {otherParty.noteMoyenne !== null && (
                    <div className="flex items-center gap-1 text-xs text-[#565E73] mt-0.5">
                      <Star className="h-3 w-3 fill-[#FC7138] text-[#FC7138]" />
                      <span className="font-bold text-[#131B2D]">{otherParty.noteMoyenne.toFixed(1)}</span>
                      <span>({otherParty.nombreAvis} avis)</span>
                    </div>
                  )}
                </div>
              </div>
              <Link
                href="/messages"
                className="flex items-center justify-center gap-2 rounded-full bg-[#131B2D] py-2.5 text-xs font-bold text-white hover:bg-[#202b45] transition-colors"
              >
                <MessageSquare className="h-3.5 w-3.5" />
                Ouvrir la conversation
              </Link>
            </div>
          )}
        </div>

        {/* ── Colonne droite ──────────────────────────────────────── */}
        <div className="space-y-5">

          {/* Statut actuel */}
          <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-[0_4px_20px_rgba(19,27,45,0.04)]">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-extrabold text-[#131B2D]">Négociation #{negId}</h2>
              <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold ${cfg.bg} ${cfg.text}`}>
                <span className={`h-2 w-2 rounded-full ${cfg.dot}`} />
                {cfg.label}
              </span>
            </div>
            <p className="text-xs text-[#76777D]">Proposée le {dateShort(dateProposition)}</p>

            {message && (
              <div className="mt-4 rounded-xl bg-[#FAF9F9] border border-[#E3E2E2]/60 p-4">
                <p className="text-xs font-bold text-[#76777D] mb-1.5">Message accompagnant l&apos;offre</p>
                <p className="text-sm text-[#131B2D] leading-relaxed">{message}</p>
              </div>
            )}
          </div>

          {/* Historique des paliers */}
          {history.length > 0 && (
            <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-[0_4px_20px_rgba(19,27,45,0.04)] space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-bold text-[#131B2D]">Historique des offres</h3>
                <span className="text-xs text-[#76777D]">{history.length} proposition{history.length > 1 ? "s" : ""}</span>
              </div>

              <div className="relative pl-5 space-y-4 before:absolute before:left-1.5 before:top-1.5 before:bottom-1.5 before:w-0.5 before:bg-[#E3E2E2]">
                {history.map((h) => {
                  const hCfg = STATUT[h.statut as keyof typeof STATUT] ?? STATUT.en_attente;
                  return (
                    <div key={h.id} className="relative">
                      <span className={`absolute -left-5 top-1 h-3 w-3 rounded-full border-2 border-white ${
                        h.isCurrent ? "ring-4 ring-[#FC7138]/20 bg-[#FC7138]" : "bg-[#76777D]"
                      }`} />
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <span className={`block text-xs font-extrabold ${h.isCurrent ? "text-[#FC7138]" : "text-[#565E73] line-through"}`}>
                            {formatFCFA(h.prix_propose)}
                          </span>
                          <span className="text-[11px] text-[#76777D]">
                            {h.isAcheteur ? "Vous (acheteur)" : "Vendeur"} · {dateShort(h.date_proposition)}
                          </span>
                          {h.message && (
                            <p className="mt-1 text-xs text-[#565E73] italic line-clamp-1">"{h.message}"</p>
                          )}
                        </div>
                        <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-bold ${hCfg.bg} ${hCfg.text}`}>
                          {hCfg.label}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>

              {savings > 0 && (
                <div className="rounded-xl bg-[#FAF9F9] border border-[#E3E2E2]/60 p-3 text-xs text-[#565E73]">
                  <TrendingDown className="inline h-3.5 w-3.5 mr-1 text-[#00966B]" />
                  Gain potentiel : <strong className="text-[#131B2D]">{formatFCFA(savings)}</strong> par rapport au prix initial.
                </div>
              )}
            </div>
          )}

          {/* Actions */}
          {isActive && (
            <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-[0_4px_20px_rgba(19,27,45,0.04)] space-y-4">
              <h3 className="text-sm font-bold text-[#131B2D]">Actions disponibles</h3>

              {!counterMode ? (
                <div className="space-y-3">
                  {/* Le vendeur peut accepter ou refuser ; l'acheteur peut annuler ou contre-proposer */}
                  {role === "vendeur" && (
                    <button
                      type="button"
                      onClick={handleAccept}
                      disabled={loading}
                      className="flex h-12 w-full items-center justify-center gap-2 rounded-full bg-[#00966B] text-sm font-bold text-white shadow-sm hover:bg-[#007f59] transition-all disabled:opacity-50"
                    >
                      <CheckCircle2 className="h-4 w-4" />
                      Accepter l&apos;offre à {formatFCFA(prixPropose)}
                    </button>
                  )}

                  <button
                    type="button"
                    onClick={() => setCounterMode(true)}
                    disabled={loading}
                    className="flex h-12 w-full items-center justify-center gap-2 rounded-full bg-[#FC7138] text-sm font-bold text-white shadow-sm hover:bg-[#e05f29] transition-all disabled:opacity-50"
                  >
                    <Handshake className="h-4 w-4" />
                    Faire une contre-proposition
                  </button>

                  <button
                    type="button"
                    onClick={role === "vendeur" ? handleRefuse : handleRefuse}
                    disabled={loading}
                    className="flex h-12 w-full items-center justify-center gap-2 rounded-full border border-[#E3E2E2] bg-white text-sm font-bold text-[#BA1A1A] hover:bg-[#FFF0F0] transition-all disabled:opacity-50"
                  >
                    <XCircle className="h-4 w-4" />
                    {role === "vendeur" ? "Refuser l'offre" : "Annuler ma proposition"}
                  </button>
                </div>
              ) : (
                /* Formulaire contre-proposition */
                <div className="space-y-4">
                  {/* Chips +% au-dessus du prix proposé */}
                  {annonce && (
                    <div>
                      <p className="text-xs font-bold text-[#131B2D] mb-2">
                        Proposer au-dessus de l&apos;offre actuelle
                      </p>
                      <p className="text-[11px] text-[#76777D] mb-3">
                        Offre en cours : <span className="font-bold text-[#FC7138]">{formatFCFA(prixPropose)}</span>
                      </p>
                      <div className="flex gap-2">
                        {[
                          { label: "+5%",  value: Math.round(prixPropose * 1.05) },
                          { label: "+10%", value: Math.round(prixPropose * 1.10) },
                          { label: "+20%", value: Math.round(prixPropose * 1.20) },
                        ].map((c) => {
                          const isSelected = counterPrice === String(c.value);
                          const exceedsOriginal = c.value >= annonce.prix_actuel;
                          return (
                            <button
                              key={c.label}
                              type="button"
                              disabled={exceedsOriginal}
                              onClick={() => setCounterPrice(String(c.value))}
                              className={`flex-1 rounded-full border px-3 py-2 text-xs font-bold transition-all disabled:opacity-40 disabled:cursor-not-allowed ${
                                isSelected
                                  ? "border-[#FC7138] bg-[#FC7138] text-white"
                                  : "border-[#E3E2E2] bg-white text-[#131B2D] hover:border-[#FC7138]"
                              }`}
                            >
                              <span className="block">{c.label}</span>
                              <span className={`block text-[10px] font-normal mt-0.5 ${isSelected ? "text-white/70" : "text-[#565E73]"}`}>
                                {c.value.toLocaleString("fr-FR")}
                              </span>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  )}

                  <div>
                    <label className="block text-xs font-bold text-[#131B2D] mb-1.5">
                      Ou saisir un prix manuellement (FCFA)
                    </label>
                    <input
                      type="number"
                      value={counterPrice}
                      onChange={(e) => setCounterPrice(e.target.value)}
                      placeholder={`Ex : ${Math.round(prixPropose * 1.08).toLocaleString("fr-FR")}`}
                      min={prixPropose + 1}
                      max={annonce?.prix_actuel ? annonce.prix_actuel - 1 : undefined}
                      className="h-11 w-full rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 text-sm font-bold text-[#131B2D] outline-none focus:border-[#FC7138] focus:bg-white focus:ring-2 focus:ring-[#FC7138]/20 transition-all"
                    />
                    {counterPrice && Number(counterPrice) <= prixPropose && (
                      <p className="mt-1 text-xs text-[#BA1A1A]">Le prix doit être supérieur à l&apos;offre actuelle.</p>
                    )}
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-[#131B2D] mb-1.5">
                      Message (optionnel)
                    </label>
                    <textarea
                      value={counterMsg}
                      onChange={(e) => setCounterMsg(e.target.value)}
                      placeholder="Expliquez votre proposition..."
                      rows={3}
                      className="w-full resize-none rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 py-3 text-sm text-[#131B2D] outline-none focus:border-[#FC7138] focus:bg-white focus:ring-2 focus:ring-[#FC7138]/20 transition-all"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setCounterMode(false)}
                      className="h-11 rounded-full border border-[#E3E2E2] bg-white text-xs font-bold text-[#565E73] hover:bg-[#F4F3F3] transition-colors"
                    >
                      Annuler
                    </button>
                    <button
                      type="button"
                      onClick={handleCounter}
                      disabled={!counterPrice || loading}
                      className="h-11 rounded-full bg-[#FC7138] text-xs font-bold text-white shadow-sm hover:bg-[#e05f29] transition-all disabled:opacity-50"
                    >
                      {loading ? "Envoi…" : "Envoyer la proposition"}
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* État terminal */}
          {!isActive && (
            <div className={`rounded-2xl border p-5 space-y-3 ${cfg.bg} border-current/10`}>
              <div className="flex items-center gap-3">
                {statut === "acceptee"
                  ? <CheckCircle2 className="h-6 w-6 text-[#00966B]" />
                  : <XCircle className="h-6 w-6 text-[#BA1A1A]" />
                }
                <div>
                  <p className={`text-sm font-extrabold ${cfg.text}`}>
                    Négociation {cfg.label.toLowerCase()}
                  </p>
                  <p className="text-xs text-[#565E73]">
                    {statut === "acceptee"
                      ? "L'accord a été conclu. Rendez-vous dans la conversation pour finaliser."
                      : "Cette négociation est clôturée."
                    }
                  </p>
                </div>
              </div>
              <Link
                href="/messages"
                className="flex items-center justify-center gap-2 rounded-full bg-[#131B2D] py-2.5 text-xs font-bold text-white hover:bg-[#202b45] transition-colors"
              >
                <MessageSquare className="h-3.5 w-3.5" />
                Aller à la conversation
              </Link>
            </div>
          )}

        </div>
      </div>
    </main>
  );
}
