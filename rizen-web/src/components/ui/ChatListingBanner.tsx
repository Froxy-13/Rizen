"use client";

import React from "react";
import Image from "next/image";
import Link from "next/link";
import { ExternalLink, Tag } from "lucide-react";
import { ChatListing } from "@/types/chat";

interface ChatListingBannerProps {
  listing: ChatListing;
  prixNegocie?: number | null;
  onMakeOfferClick?: () => void;
}

export function ChatListingBanner({ listing, prixNegocie, onMakeOfferClick }: ChatListingBannerProps) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-3.5 mx-4 mt-3 rounded-2xl border border-[#E3E2E2]/60 shadow-[0_2px_12px_rgba(19,27,45,0.04)] shrink-0">
      <div className="flex items-center gap-3 min-w-0">
        <div className="relative h-12 w-12 shrink-0 overflow-hidden rounded-xl bg-[#F4F3F3]">
          <Image src={listing.image} alt={listing.title} fill className="object-cover" />
        </div>
        <div className="min-w-0">
          <h2 className="text-xs md:text-sm font-bold text-[#1A1C1C] truncate">{listing.title}</h2>
          <div className="flex items-center gap-2 mt-0.5 flex-wrap">
            {prixNegocie ? (
              <>
                <span className="text-xs font-semibold text-[#76777D] line-through">
                  {listing.price.toLocaleString("fr-FR")} FCFA
                </span>
                <span className="text-sm md:text-base font-black text-[#00966B]">
                  {prixNegocie.toLocaleString("fr-FR")} FCFA
                </span>
                <span className="rounded-full bg-[#E8F5EE] px-2 py-0.5 text-[10px] font-bold text-[#00966B]">
                  Négocié
                </span>
              </>
            ) : (
              <span className="text-sm md:text-base font-black text-[#FC7138]">
                {listing.price.toLocaleString("fr-FR")} FCFA
              </span>
            )}
            <span className="text-xs text-[#76777D]">· {listing.location}</span>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 shrink-0">
        <Link
          href={listing.url}
          className="flex h-9 items-center gap-1.5 rounded-full border border-[#131B2D]/20 bg-white px-3.5 text-xs font-bold text-[#131B2D] hover:bg-[#F4F3F3] transition-colors"
        >
          Voir l'annonce
          <ExternalLink className="h-3 w-3" />
        </Link>
        <button
          type="button"
          onClick={onMakeOfferClick}
          className="flex h-9 items-center gap-1.5 rounded-full bg-[#FC7138] px-4 text-xs font-bold text-white shadow-[0_4px_14px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] transition-all active:scale-95"
        >
          <Tag className="h-3 w-3" />
          Faire une offre
        </button>
      </div>
    </div>
  );
}
