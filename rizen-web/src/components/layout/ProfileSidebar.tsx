"use client";

import React from "react";
import Link from "next/link";
import {
  Store,
  Heart,
  MessageSquareQuote,
  ArrowLeftRight,
  Settings,
  ShieldCheck,
  PlusCircle,
} from "lucide-react";

interface Counts {
  annonces: number;
  favoris: number;
  avis: number;
}

interface ProfileSidebarProps {
  activeTab?: string;
  counts?: Counts;
}

export function ProfileSidebar({ activeTab = "annonces", counts }: ProfileSidebarProps) {
  return (
    <aside className="w-full lg:w-[260px] shrink-0 space-y-6">
      <div className="rounded-2xl border border-[#E3E2E2]/60 bg-white p-4 shadow-[0_4px_20px_rgba(19,27,45,0.04)]">
        {/* Espace Vendeur */}
        <div className="mb-6">
          <h4 className="px-3 text-[11px] font-bold uppercase tracking-wider text-[#76777D] mb-2">
            Espace Vendeur
          </h4>
          <nav className="space-y-1">
            <Link
              href="/profil"
              className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-semibold transition-all ${
                activeTab === "annonces"
                  ? "bg-[#FFDBBF]/40 text-[#FC7138]"
                  : "text-[#1A1C1C] hover:bg-[#F4F3F3]"
              }`}
            >
              <span className="flex items-center gap-3">
                <Store className="h-4 w-4" />
                Mes annonces
              </span>
              {counts && counts.annonces > 0 && (
                <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-[#FC7138] px-1.5 text-[11px] font-bold text-white">
                  {counts.annonces}
                </span>
              )}
            </Link>

            <Link
              href="/favoris"
              className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-semibold transition-all ${
                activeTab === "favoris"
                  ? "bg-[#FFDBBF]/40 text-[#FC7138]"
                  : "text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C]"
              }`}
            >
              <span className="flex items-center gap-3">
                <Heart className="h-4 w-4" />
                Favoris
              </span>
              {counts && counts.favoris > 0 && (
                <span className="text-xs text-[#76777D]">{counts.favoris}</span>
              )}
            </Link>

            <Link
              href="/profil/avis"
              className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-semibold transition-all ${
                activeTab === "avis"
                  ? "bg-[#FFDBBF]/40 text-[#FC7138]"
                  : "text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C]"
              }`}
            >
              <span className="flex items-center gap-3">
                <MessageSquareQuote className="h-4 w-4" />
                Avis clients
              </span>
              {counts && counts.avis > 0 && (
                <span className="text-xs font-bold text-[#00966B]">{counts.avis}</span>
              )}
            </Link>

            <Link
              href="/profil/transactions"
              className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-semibold transition-all ${
                activeTab === "transactions"
                  ? "bg-[#FFDBBF]/40 text-[#FC7138]"
                  : "text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C]"
              }`}
            >
              <span className="flex items-center gap-3">
                <ArrowLeftRight className="h-4 w-4" />
                Transactions
              </span>
            </Link>
          </nav>
        </div>

        {/* Mon Compte */}
        <div>
          <h4 className="px-3 text-[11px] font-bold uppercase tracking-wider text-[#76777D] mb-2">
            Mon Compte
          </h4>
          <nav className="space-y-1">
            <Link
              href="/parametres"
              className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-all ${
                activeTab === "parametres"
                  ? "bg-[#FFDBBF]/40 text-[#FC7138]"
                  : "text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C]"
              }`}
            >
              <Settings className="h-4 w-4" />
              Paramètres
            </Link>

            <Link
              href="/conseils-securite"
              className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold text-[#565E73] hover:bg-[#F4F3F3] hover:text-[#1A1C1C] transition-all"
            >
              <ShieldCheck className="h-4 w-4 text-[#00966B]" />
              Sécurité & Teranga
            </Link>
          </nav>
        </div>

        {/* CTA */}
        <div className="mt-6 pt-4 border-t border-[#F4F3F3]">
          <Link
            href="/annonces/creer"
            className="flex items-center justify-center gap-2 rounded-full bg-[#FC7138] px-4 py-3 text-sm font-bold text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] transition-all"
          >
            <PlusCircle className="h-4 w-4" />
            Publier une annonce
          </Link>
        </div>
      </div>
    </aside>
  );
}
