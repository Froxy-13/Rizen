"use client";

import React from "react";
import Link from "next/link";
import Image from "next/image";
import { X } from "lucide-react";

interface CreateListingHeaderProps {
  prenom?: string | null;
  photo?: string | null;
}

export function CreateListingHeader({ prenom, photo }: CreateListingHeaderProps) {
  const initiale = prenom ? prenom[0].toUpperCase() : "?";

  return (
    <header className="sticky top-0 z-40 h-[68px] border-b border-[#E3E2E2] bg-white px-6">
      <div className="mx-auto flex h-full max-w-[1280px] items-center justify-between">
        <Link
          href="/feed"
          className="flex items-center gap-1.5 text-xs font-bold text-[#131B2D] hover:text-[#FC7138] transition-colors"
        >
          <X className="h-4 w-4" />
          <span>Quitter</span>
        </Link>

        <div className="text-center">
          <h1 className="text-base font-extrabold text-[#131B2D] tracking-tight">
            Publier une annonce
          </h1>
          <p className="text-[11px] font-medium text-[#76777D]">
            Rizen Marketplace
          </p>
        </div>

        <div className="relative h-9 w-9 rounded-full bg-[#FFDBBF] flex items-center justify-center overflow-hidden ring-2 ring-[#131B2D]/10 shrink-0">
          {photo ? (
            <Image src={photo} alt={prenom ?? "Profil"} fill className="object-cover" />
          ) : (
            <span className="text-[#FC7138] font-bold text-sm">{initiale}</span>
          )}
        </div>
      </div>
    </header>
  );
}
