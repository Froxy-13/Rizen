"use client";

import React, { useState, Suspense } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { AuthGateCard, AuthGateAction } from "@/components/ui/AuthGateCard";
import { AuthGateFallback } from "@/components/ui/AuthGateFallback";

function GateContent() {
  const searchParams = useSearchParams();
  const returnUrl = searchParams.get("redirect") || "/";
  const initialAction = (searchParams.get("action") as AuthGateAction) || "favoris";
  const [selectedAction, setSelectedAction] = useState<AuthGateAction>(initialAction);

  const ACTIONS: AuthGateAction[] = ["favoris", "message", "acheter", "negocier", "publier"];

  return (
    <div className="min-h-screen bg-[#FAF9F9] flex flex-col font-[Plus_Jakarta_Sans,sans-serif]">
      {/* Navbar publique */}
      <header className="sticky top-0 z-50 h-[72px] bg-[#131B2D] px-6 shadow-md">
        <div className="mx-auto flex h-full max-w-[1280px] items-center justify-between gap-6">
          <Link href="/" className="flex items-center gap-2 shrink-0">
            <Image src="/Rizen.png" alt="Rizen" width={90} height={28} priority className="object-contain" />
          </Link>

          <div className="flex items-center gap-3 text-xs font-semibold">
            <Link
              href="/auth/login"
              className="px-4 py-2 text-white/80 hover:text-white transition-colors"
            >
              Se connecter
            </Link>
            <Link
              href="/auth/register"
              className="rounded-full bg-[#FC7138] px-5 py-2.5 font-bold text-white shadow hover:bg-[#e05f29] transition-all"
            >
              Rejoindre
            </Link>
          </div>
        </div>
      </header>

      {/* Barre de contexte */}
      <div className="border-b border-[#E3E2E2] bg-white px-6 py-2.5">
        <div className="mx-auto flex max-w-[1280px] flex-wrap items-center justify-between gap-3">
          <nav className="flex items-center gap-1.5 text-xs text-[#76777D]">
            <Link href="/" className="hover:text-[#131B2D] transition-colors">Accueil</Link>
            <span>›</span>
            <span className="font-semibold text-[#1A1C1C]">Espace réservé</span>
          </nav>

          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs font-semibold text-[#1A1C1C]">Contexte :</span>
            {ACTIONS.map((act) => (
              <button
                key={act}
                type="button"
                onClick={() => setSelectedAction(act)}
                className={`rounded-full px-3 py-1 text-xs font-bold transition-all capitalize ${
                  selectedAction === act
                    ? "bg-[#FC7138] text-white shadow-sm"
                    : "bg-[#F4F3F3] text-[#565E73] hover:bg-[#E3E2E2]"
                }`}
              >
                {act}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Contenu */}
      <main className="flex-1 py-12 px-6">
        <div className="mx-auto max-w-[1280px] space-y-16">
          {/* Carte centrale */}
          <div className="flex justify-center">
            <AuthGateCard action={selectedAction} returnUrl={returnUrl} />
          </div>

          {/* Fallback pleine largeur — tel qu'il apparaît sur /favoris, /profil, /notifications */}
          <div className="pt-10 border-t border-[#E3E2E2]">
            <div className="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-[#FC7138]">
                  Intégration inline
                </span>
                <h2 className="text-lg font-bold text-[#131B2D]">
                  Bloc de garde sur /favoris, /notifications & /profil
                </h2>
              </div>
              <span className="text-xs text-[#76777D]">Accès direct non authentifié</span>
            </div>
            <AuthGateFallback returnUrl={returnUrl} />
          </div>
        </div>
      </main>

      {/* Footer minimal */}
      <footer className="border-t border-[#E3E2E2] bg-white px-6 py-6">
        <div className="mx-auto flex max-w-[1280px] flex-col md:flex-row items-center justify-between gap-4 text-xs text-[#76777D]">
          <div className="flex items-center gap-2">
            <Image src="/Rizen.png" alt="Rizen" width={56} height={18} className="object-contain opacity-60" />
            <span>© {new Date().getFullYear()} Rizen Marketplace · Dakar, Sénégal</span>
          </div>
          <nav className="flex items-center gap-6 font-semibold">
            <Link href="/cgu" className="hover:text-[#131B2D] transition-colors">CGU</Link>
            <Link href="/confidentialite" className="hover:text-[#131B2D] transition-colors">Confidentialité</Link>
            <Link href="/conseils-securite" className="hover:text-[#131B2D] transition-colors">Conseils sécurité</Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}

export default function AuthGatePage() {
  return (
    <Suspense>
      <GateContent />
    </Suspense>
  );
}
