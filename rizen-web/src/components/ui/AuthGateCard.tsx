"use client";

import React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Lock, CheckCircle2, ShieldCheck } from "lucide-react";

export type AuthGateAction = "favoris" | "message" | "acheter" | "negocier" | "publier";

interface AuthGateCardProps {
  action?: AuthGateAction;
  returnUrl?: string;
}

const ACTION_LABELS: Record<AuthGateAction, string> = {
  favoris:  "sauvegarder cette annonce dans vos favoris",
  message:  "contacter ce vendeur",
  acheter:  "finaliser cet achat",
  negocier: "faire une offre au vendeur",
  publier:  "mettre en vente un article",
};

export function AuthGateCard({ action = "favoris", returnUrl = "/" }: AuthGateCardProps) {
  const router = useRouter();
  const actionText = ACTION_LABELS[action];

  const handleBack = () => {
    if (window.history.length > 1) {
      router.back();
    } else {
      router.push(returnUrl);
    }
  };

  return (
    <div className="w-full max-w-[480px] rounded-[24px] bg-white p-8 md:p-12 shadow-[0_4px_20px_rgba(19,27,45,0.05)] border border-[#E3E2E2]/60 text-center">
      {/* Icône */}
      <div className="mx-auto flex h-[120px] w-[120px] items-center justify-center rounded-[24px] bg-[#FFF7F4]">
        <Lock className="h-12 w-12 text-[#FC7138]" strokeWidth={1.5} />
      </div>

      {/* Titre & sous-titre contextuel */}
      <h1 className="mt-8 text-2xl font-bold tracking-tight text-[#131B2D] leading-snug">
        Cette fonctionnalité est réservée aux membres
      </h1>
      <p className="mt-3 text-sm leading-relaxed text-[#565E73]">
        Créez un compte gratuit ou connectez-vous pour{" "}
        <span className="font-semibold text-[#1A1C1C]">{actionText}</span>.
      </p>

      {/* Avantages */}
      <div className="mt-8 space-y-2.5 text-left">
        {[
          "Achat 100% sécurisé Téranga",
          "Vendeurs vérifiés Dakar",
          "Inscription en 30 secondes",
        ].map((label) => (
          <div
            key={label}
            className="flex items-center gap-3 rounded-xl bg-[#FAF9F9] px-4 py-3 border border-[#E3E2E2]/40"
          >
            <CheckCircle2 className="h-5 w-5 shrink-0 fill-[#00966B] text-white" />
            <span className="text-xs font-semibold text-[#1A1C1C]">{label}</span>
          </div>
        ))}
      </div>

      {/* CTAs */}
      <div className="mt-8 space-y-3">
        <Link
          href={`/auth/register?redirect=${encodeURIComponent(returnUrl)}`}
          className="flex h-[52px] w-full items-center justify-center rounded-full bg-[#FC7138] px-6 text-sm font-bold text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] transition-all active:scale-[0.99]"
        >
          Créer un compte gratuit
        </Link>
        <Link
          href={`/auth/login?redirect=${encodeURIComponent(returnUrl)}`}
          className="flex h-[48px] w-full items-center justify-center rounded-full border border-[#131B2D] bg-white px-6 text-sm font-bold text-[#131B2D] hover:bg-[#F4F3F3] transition-all active:scale-[0.99]"
        >
          J'ai déjà un compte — Se connecter
        </Link>
      </div>

      {/* Retour */}
      <div className="mt-6">
        <button
          type="button"
          onClick={handleBack}
          className="inline-flex items-center gap-1 text-xs font-semibold text-[#76777D] hover:text-[#131B2D] transition-colors"
        >
          Continuer à explorer sans compte →
        </button>
      </div>

      {/* Réassurance bas */}
      <div className="mt-6 flex items-center justify-center gap-1.5 text-[11px] text-[#76777D]">
        <ShieldCheck className="h-3.5 w-3.5 text-[#00966B]" />
        <span>Protection des transactions et confidentialité certifiées au Sénégal</span>
      </div>
    </div>
  );
}
