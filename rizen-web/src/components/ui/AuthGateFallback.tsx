"use client";

import React from "react";
import Link from "next/link";
import { UserX, RefreshCw, BadgeCheck, BellRing } from "lucide-react";

interface AuthGateFallbackProps {
  title?: string;
  description?: string;
  returnUrl?: string;
}

export function AuthGateFallback({
  title = "Connectez-vous pour accéder à votre espace",
  description = "Retrouvez vos articles sauvegardés, vos alertes instantanées et l'historique de vos échanges avec les vendeurs certifiés de Dakar.",
  returnUrl = "/",
}: AuthGateFallbackProps) {
  return (
    <section className="w-full rounded-[24px] border border-[#E3E2E2]/60 bg-white p-8 md:p-14 shadow-[0_4px_20px_rgba(19,27,45,0.03)] text-center">
      {/* Icône */}
      <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-[#FAF9F9]">
        <UserX className="h-10 w-10 text-[#E3E2E2]" strokeWidth={1} />
      </div>

      <h2 className="mt-6 text-xl md:text-2xl font-bold tracking-tight text-[#131B2D]">
        {title}
      </h2>
      <p className="mx-auto mt-2 max-w-[460px] text-xs md:text-sm leading-relaxed text-[#565E73]">
        {description}
      </p>

      {/* CTAs */}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
        <Link
          href={`/auth/register?redirect=${encodeURIComponent(returnUrl)}`}
          className="flex h-[46px] min-w-[170px] items-center justify-center rounded-full bg-[#FC7138] px-6 text-xs md:text-sm font-bold text-white shadow-[0_6px_20px_rgba(252,113,56,0.2)] hover:bg-[#e05f29] transition-all active:scale-95"
        >
          Créer un compte
        </Link>
        <Link
          href={`/auth/login?redirect=${encodeURIComponent(returnUrl)}`}
          className="flex h-[46px] min-w-[150px] items-center justify-center rounded-full border border-[#131B2D] bg-white px-6 text-xs md:text-sm font-bold text-[#131B2D] hover:bg-[#F4F3F3] transition-all active:scale-95"
        >
          Se connecter
        </Link>
      </div>

      {/* Piliers */}
      <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-4 border-t border-[#F4F3F3] pt-8 text-left">
        <div className="rounded-xl bg-[#FAF9F9] p-4 border border-[#E3E2E2]/40">
          <div className="flex items-center gap-2 text-xs font-bold text-[#131B2D]">
            <RefreshCw className="h-4 w-4 text-[#FC7138] shrink-0" />
            <span>Synchronisation automatique</span>
          </div>
          <p className="mt-1 text-[11px] leading-relaxed text-[#565E73]">
            Vos actions locales sont mémorisées temporairement et rattachées dès votre authentification.
          </p>
        </div>

        <div className="rounded-xl bg-[#FAF9F9] p-4 border border-[#E3E2E2]/40">
          <div className="flex items-center gap-2 text-xs font-bold text-[#131B2D]">
            <BadgeCheck className="h-4 w-4 text-[#00966B] shrink-0" />
            <span>Confiance & Téranga</span>
          </div>
          <p className="mt-1 text-[11px] leading-relaxed text-[#565E73]">
            Identité contrôlée des commerçants des marchés Sandaga, HLM et Kermel.
          </p>
        </div>

        <div className="rounded-xl bg-[#FAF9F9] p-4 border border-[#E3E2E2]/40">
          <div className="flex items-center gap-2 text-xs font-bold text-[#131B2D]">
            <BellRing className="h-4 w-4 text-[#131B2D] shrink-0" />
            <span>Alertes temps réel</span>
          </div>
          <p className="mt-1 text-[11px] leading-relaxed text-[#565E73]">
            Notifications SMS et web dès qu'une baisse de prix ou réponse marchand intervient.
          </p>
        </div>
      </div>
    </section>
  );
}
