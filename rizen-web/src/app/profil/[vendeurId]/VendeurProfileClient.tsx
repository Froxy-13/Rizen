"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import {
  MessageSquare,
  Flag,
  CheckCircle2,
  Star,
  Tag,
  MapPin,
  Calendar,
  ChevronRight,
  Package,
} from "lucide-react";

// ─── Types ────────────────────────────────────────────────────────────────────

interface Annonce {
  id: number;
  titre: string;
  prix_actuel: number;
  prix_initial: number;
  ville: string | null;
  quartier: string | null;
  date_publication: string;
  imageUrl: string;
}

interface Avis {
  note: number;
  commentaire: string | null;
  date_avis: string;
  acheteur: { nom: string; prenom: string | null; photo: string | null } | null;
}

interface VendeurProfileClientProps {
  vendeurId: string;
  nom: string;
  prenom: string | null;
  photo: string | null;
  bio: string | null;
  ville: string | null;
  certifie: boolean;
  noteMoyenne: number | null;
  nombreAvis: number;
  nombreVentes: number;
  dateInscription: string;
  annonces: Annonce[];
  avis: Avis[];
  currentUserId: string | null;
  isOwnProfile: boolean;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function timeAgo(date: string) {
  const diff = Date.now() - new Date(date).getTime();
  const days = Math.floor(diff / 86400000);
  if (days === 0) return "Aujourd'hui";
  if (days === 1) return "Hier";
  if (days < 30) return `Il y a ${days}j`;
  return new Date(date).toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
}

function memberSince(date: string) {
  return new Date(date).toLocaleDateString("fr-FR", { month: "long", year: "numeric" });
}

const PLACEHOLDER = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

// ─── Component ───────────────────────────────────────────────────────────────

export function VendeurProfileClient({
  vendeurId,
  nom,
  prenom,
  photo,
  bio,
  ville,
  certifie,
  noteMoyenne,
  nombreAvis,
  nombreVentes,
  dateInscription,
  annonces,
  avis,
  currentUserId,
  isOwnProfile,
}: VendeurProfileClientProps) {
  const [activeTab, setActiveTab] = useState<"listings" | "reviews">("listings");
  const [visibleCount, setVisibleCount] = useState(8);

  const vendeurNom = `${prenom ?? ""} ${nom}`.trim();
  const isNegociable = (a: Annonce) => a.prix_initial > a.prix_actuel;

  return (
    <div className="flex flex-col">

      {/* ── Hero section dark navy ──────────────────────────────────── */}
      <section className="bg-[#131B2D] text-white py-10 px-6">
        <div className="mx-auto max-w-[1280px]">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">

            {/* Identité */}
            <div className="flex items-start gap-5">
              <div className="relative h-20 w-20 md:h-24 md:w-24 shrink-0 rounded-full overflow-hidden ring-4 ring-white/10 bg-[#FFDBBF]">
                {photo ? (
                  <Image src={photo} alt={vendeurNom} fill className="object-cover" />
                ) : (
                  <span className="flex h-full w-full items-center justify-center text-2xl font-extrabold text-[#FC7138]">
                    {vendeurNom[0]?.toUpperCase()}
                  </span>
                )}
              </div>

              <div className="space-y-1.5">
                <div className="flex flex-wrap items-center gap-3">
                  <h1 className="text-2xl md:text-3xl font-extrabold tracking-tight text-white">
                    {vendeurNom}
                  </h1>
                  {certifie && (
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-[#00966B]/20 px-3 py-1 text-xs font-bold text-[#00966B] border border-[#00966B]/30">
                      <CheckCircle2 className="h-3.5 w-3.5 fill-[#00966B] text-[#131B2D]" />
                      Vendeur Certifié Dakar
                    </span>
                  )}
                </div>

                <div className="flex flex-wrap items-center gap-y-1 gap-x-3 text-xs text-white/80">
                  {noteMoyenne !== null ? (
                    <div className="flex items-center gap-1 font-bold text-white">
                      <Star className="h-4 w-4 fill-[#FC7138] text-[#FC7138]" />
                      <span>{noteMoyenne.toFixed(1)}</span>
                      <span className="text-white/60 font-normal">({nombreAvis} avis)</span>
                    </div>
                  ) : (
                    <span className="text-white/50 text-xs">Aucun avis pour l&apos;instant</span>
                  )}
                  {ville && (
                    <>
                      <span className="text-white/30">·</span>
                      <div className="flex items-center gap-1">
                        <MapPin className="h-3.5 w-3.5 text-[#FC7138]" />
                        <span>{ville}</span>
                      </div>
                    </>
                  )}
                </div>

                <div className="flex items-center gap-2 text-[11px] text-white/50">
                  <Calendar className="h-3.5 w-3.5" />
                  <span>Membre depuis {memberSince(dateInscription)}</span>
                </div>

                {bio && (
                  <p className="mt-1 text-xs text-white/70 max-w-md leading-relaxed">{bio}</p>
                )}
              </div>
            </div>

            {/* CTAs */}
            <div className="flex flex-col items-start md:items-end gap-3 shrink-0">
              {isOwnProfile ? (
                <Link
                  href="/profil/modifier"
                  className="flex h-11 items-center gap-2 rounded-full border border-white/20 bg-white/10 px-6 text-xs font-bold text-white hover:bg-white/15 transition-all"
                >
                  Modifier mon profil
                </Link>
              ) : (
                <Link
                  href={currentUserId ? `/messages` : `/auth/gate?redirect=/profil/${vendeurId}`}
                  className="flex h-11 items-center gap-2 rounded-full bg-[#FC7138] px-6 text-xs font-bold text-white shadow-[0_4px_16px_rgba(252,113,56,0.3)] hover:bg-[#e05f29] transition-all active:scale-95"
                >
                  <MessageSquare className="h-4 w-4" />
                  Envoyer un message
                </Link>
              )}

              {!isOwnProfile && (
                <button
                  type="button"
                  className="flex items-center gap-1.5 text-[11px] font-semibold text-white/50 hover:text-white/80 transition-colors"
                >
                  <Flag className="h-3.5 w-3.5" />
                  Signaler ce profil
                </button>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* ── Corps de la page ──────────────────────────────────────────── */}
      <main className="flex-1 py-10 px-6">
        <div className="mx-auto max-w-[1280px] space-y-10">

          {/* Stats (3 cartes) */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div className="flex items-center justify-between rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.03)]">
              <div>
                <span className="text-xs font-bold text-[#76777D]">Annonces actives</span>
                <div className="mt-1 text-3xl font-black text-[#131B2D]">{annonces.length}</div>
                <p className="mt-1 text-xs text-[#565E73]">En ce moment sur Rizen</p>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#FFF7F4] text-[#FC7138]">
                <Tag className="h-6 w-6" />
              </div>
            </div>

            <div className="flex items-center justify-between rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.03)]">
              <div>
                <span className="text-xs font-bold text-[#76777D]">Ventes conclues</span>
                <div className="mt-1 text-3xl font-black text-[#131B2D]">{nombreVentes}</div>
                <p className="mt-1 text-xs text-[#565E73]">
                  {nombreVentes === 0 ? "Nouveau vendeur" : "Remises en mains propres"}
                </p>
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#E8F8F2] text-[#00966B]">
                <CheckCircle2 className="h-6 w-6" />
              </div>
            </div>

            <div className="flex items-center justify-between rounded-2xl border border-[#E3E2E2]/60 bg-white p-6 shadow-[0_4px_20px_rgba(19,27,45,0.03)]">
              <div>
                <span className="text-xs font-bold text-[#76777D]">Note moyenne</span>
                {noteMoyenne !== null ? (
                  <>
                    <div className="mt-1 flex items-baseline gap-2">
                      <span className="text-3xl font-black text-[#131B2D]">{noteMoyenne.toFixed(1)}</span>
                      <div className="flex">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <Star
                            key={i}
                            className={`h-4 w-4 ${i < Math.round(noteMoyenne) ? "fill-[#FC7138] text-[#FC7138]" : "text-[#E3E2E2]"}`}
                          />
                        ))}
                      </div>
                    </div>
                    <p className="mt-1 text-xs text-[#565E73]">{nombreAvis} évaluation{nombreAvis !== 1 ? "s" : ""}</p>
                  </>
                ) : (
                  <>
                    <div className="mt-1 text-3xl font-black text-[#E3E2E2]">—</div>
                    <p className="mt-1 text-xs text-[#565E73]">Pas encore d&apos;avis</p>
                  </>
                )}
              </div>
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#F4F3F3] text-[#131B2D]">
                <Star className="h-6 w-6" />
              </div>
            </div>
          </div>

          {/* Onglets */}
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setActiveTab("listings")}
              className={`rounded-full px-6 py-2.5 text-xs font-bold transition-all ${
                activeTab === "listings"
                  ? "bg-[#FC7138] text-white shadow-md"
                  : "bg-white text-[#565E73] border border-[#E3E2E2] hover:bg-[#F4F3F3]"
              }`}
            >
              Annonces en vente ({annonces.length})
            </button>
            <button
              type="button"
              onClick={() => setActiveTab("reviews")}
              className={`rounded-full px-6 py-2.5 text-xs font-bold transition-all ${
                activeTab === "reviews"
                  ? "bg-[#FC7138] text-white shadow-md"
                  : "bg-white text-[#565E73] border border-[#E3E2E2] hover:bg-[#F4F3F3]"
              }`}
            >
              Avis ({nombreAvis})
            </button>
          </div>

          {/* ── Onglet Annonces ──────────────────────────────────────── */}
          {activeTab === "listings" && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-extrabold text-[#131B2D] tracking-tight">
                  Catalogue de {prenom ?? nom}
                </h2>
                <span className="text-xs text-[#76777D]">Plus récentes en premier</span>
              </div>

              {annonces.length === 0 ? (
                <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
                  <div className="flex h-16 w-16 items-center justify-center rounded-full bg-[#F4F3F3]">
                    <Package className="h-7 w-7 text-[#E3E2E2]" strokeWidth={1} />
                  </div>
                  <p className="text-sm font-semibold text-[#131B2D]">Aucune annonce active</p>
                </div>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
                    {annonces.slice(0, visibleCount).map((a) => (
                      <Link
                        key={a.id}
                        href={`/annonces/${a.id}`}
                        className="group flex flex-col rounded-2xl border border-[#E3E2E2]/60 bg-white shadow-[0_4px_20px_rgba(19,27,45,0.04)] overflow-hidden transition-all duration-200 hover:-translate-y-1 hover:shadow-[0_12px_28px_rgba(19,27,45,0.08)]"
                      >
                        <div className="relative aspect-[4/3] w-full overflow-hidden bg-[#F4F3F3]">
                          <Image
                            src={a.imageUrl ?? PLACEHOLDER}
                            alt={a.titre}
                            fill
                            sizes="(max-width: 768px) 50vw, 25vw"
                            className="object-cover transition-transform duration-300 group-hover:scale-105"
                          />
                          {isNegociable(a) && (
                            <span className="absolute top-3 left-3 rounded-full bg-[#131B2D]/85 backdrop-blur-sm px-2.5 py-0.5 text-[10px] font-bold text-white">
                              Négociable
                            </span>
                          )}
                        </div>
                        <div className="flex flex-1 flex-col p-3.5">
                          <p className="text-base font-black text-[#FC7138] tracking-tight">
                            {a.prix_actuel.toLocaleString("fr-FR")} FCFA
                          </p>
                          <h3 className="mt-1 line-clamp-2 text-xs font-bold text-[#131B2D] group-hover:text-[#FC7138] transition-colors leading-snug">
                            {a.titre}
                          </h3>
                          <div className="mt-2.5 flex items-center justify-between border-t border-[#F4F3F3] pt-2 text-[11px] text-[#76777D]">
                            <div className="flex items-center gap-1 truncate">
                              <MapPin className="h-3 w-3 shrink-0" />
                              <span className="truncate">{a.quartier ?? a.ville ?? "Dakar"}</span>
                            </div>
                            <span className="shrink-0">{timeAgo(a.date_publication)}</span>
                          </div>
                        </div>
                      </Link>
                    ))}
                  </div>

                  {visibleCount < annonces.length && (
                    <div className="flex justify-center pt-2">
                      <button
                        type="button"
                        onClick={() => setVisibleCount((c) => c + 8)}
                        className="flex items-center gap-1.5 rounded-full bg-[#F4F3F3] px-8 py-3 text-xs font-bold text-[#131B2D] hover:bg-[#E3E2E2] transition-all active:scale-95"
                      >
                        Voir {Math.min(8, annonces.length - visibleCount)} annonce{Math.min(8, annonces.length - visibleCount) > 1 ? "s" : ""} de plus
                        <ChevronRight className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  )}
                </>
              )}
            </div>
          )}

          {/* ── Onglet Avis ─────────────────────────────────────────── */}
          {activeTab === "reviews" && (
            <div className="space-y-4">
              <h2 className="text-xl font-extrabold text-[#131B2D]">
                Avis des acheteurs
              </h2>

              {avis.length === 0 ? (
                <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-10 text-center">
                  <p className="text-sm font-bold text-[#131B2D]">Aucun avis pour l&apos;instant</p>
                  <p className="mt-1 text-xs text-[#565E73]">
                    Les avis apparaissent après une transaction conclue.
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {avis.map((a, i) => {
                    const acheteurNom = a.acheteur
                      ? `${a.acheteur.prenom ?? ""} ${a.acheteur.nom}`.trim()
                      : "Acheteur";
                    return (
                      <div
                        key={i}
                        className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-5 shadow-[0_4px_20px_rgba(19,27,45,0.03)]"
                      >
                        <div className="flex items-start gap-3">
                          <div className="relative h-10 w-10 rounded-full overflow-hidden bg-[#FFDBBF] shrink-0">
                            {a.acheteur?.photo ? (
                              <Image src={a.acheteur.photo} alt={acheteurNom} fill className="object-cover" />
                            ) : (
                              <span className="flex h-full w-full items-center justify-center text-xs font-bold text-[#FC7138]">
                                {acheteurNom[0]?.toUpperCase()}
                              </span>
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between gap-2 flex-wrap">
                              <p className="text-sm font-bold text-[#131B2D]">{acheteurNom}</p>
                              <div className="flex items-center gap-1">
                                {Array.from({ length: 5 }).map((_, s) => (
                                  <Star
                                    key={s}
                                    className={`h-3.5 w-3.5 ${s < a.note ? "fill-[#FC7138] text-[#FC7138]" : "text-[#E3E2E2]"}`}
                                  />
                                ))}
                              </div>
                            </div>
                            {a.commentaire && (
                              <p className="mt-1.5 text-sm text-[#565E73] leading-relaxed">
                                {a.commentaire}
                              </p>
                            )}
                            <p className="mt-1.5 text-[11px] text-[#76777D]">{timeAgo(a.date_avis)}</p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

        </div>
      </main>
    </div>
  );
}
