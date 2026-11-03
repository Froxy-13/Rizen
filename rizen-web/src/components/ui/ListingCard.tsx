"use client";

import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Heart, CheckCircle2, MapPin, Clock } from "lucide-react";

export interface Listing {
  id: string;
  title: string;
  price: number;
  priceUnit?: string;
  image: string;
  condition?: string;
  location: string;
  postedTime: string;
  seller: {
    name: string;
    avatar: string;
    verified: boolean;
  };
}

interface ListingCardProps {
  listing: Listing;
  onFavoriteToggle?: (id: string, isFav: boolean) => void;
}

export function ListingCard({ listing, onFavoriteToggle }: ListingCardProps) {
  const [isFavorite, setIsFavorite] = useState(false);

  const handleFavoriteClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const nextState = !isFavorite;
    setIsFavorite(nextState);
    onFavoriteToggle?.(listing.id, nextState);
  };

  const formattedPrice = `${listing.price.toLocaleString("fr-FR")} FCFA${
    listing.priceUnit ? ` ${listing.priceUnit}` : ""
  }`;

  return (
    <article className="group relative flex flex-col rounded-2xl bg-white border border-[#E3E2E2]/60 overflow-hidden shadow-[0_4px_20px_rgba(19,27,45,0.05)] hover:shadow-[0_8px_30px_rgba(19,27,45,0.1)] transition-all duration-200">
      <div className="relative aspect-[4/3] w-full overflow-hidden bg-[#F4F3F3]">
        <Image
          src={listing.image}
          alt={listing.title}
          fill
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 25vw"
          className="object-cover transition-transform duration-300 group-hover:scale-105"
        />
        {listing.condition && (
          <span className="absolute top-3 left-3 rounded-full bg-[#131B2D]/85 backdrop-blur-md px-3 py-1 text-xs font-semibold text-white tracking-wide shadow-sm">
            {listing.condition}
          </span>
        )}
        <button
          type="button"
          onClick={handleFavoriteClick}
          aria-label={isFavorite ? "Retirer des favoris" : "Ajouter aux favoris"}
          className="absolute top-3 right-3 flex h-9 w-9 items-center justify-center rounded-full bg-white/90 backdrop-blur-sm text-[#131B2D] transition-all hover:bg-white hover:scale-110 active:scale-95 shadow-sm"
        >
          <Heart
            className={`h-5 w-5 transition-colors ${
              isFavorite ? "fill-[#FC7138] text-[#FC7138]" : "text-[#131B2D]"
            }`}
          />
        </button>
      </div>

      <div className="flex flex-1 flex-col p-4 justify-between">
        <div>
          <div className="text-lg font-bold text-[#131B2D] tracking-tight">
            {formattedPrice}
          </div>
          <Link href={`/annonces/${listing.id}`} className="mt-1 block">
            <h3 className="line-clamp-2 text-sm font-medium text-[#1A1C1C] group-hover:text-[#FC7138] transition-colors leading-snug">
              {listing.title}
            </h3>
          </Link>
        </div>

        <div className="mt-4 pt-3 border-t border-[#F4F3F3]">
          <div className="flex items-center justify-between text-xs text-[#76777D] mb-2.5">
            <span className="flex items-center gap-1 truncate max-w-[65%]">
              <MapPin className="h-3.5 w-3.5 shrink-0" />
              <span className="truncate">{listing.location}</span>
            </span>
            <span className="flex items-center gap-1 shrink-0">
              <Clock className="h-3 w-3 shrink-0" />
              <span>{listing.postedTime}</span>
            </span>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 min-w-0">
              <div className="relative h-6 w-6 shrink-0 rounded-full overflow-hidden bg-[#FFDBBF]">
                <Image
                  src={listing.seller.avatar}
                  alt={listing.seller.name}
                  fill
                  className="object-cover"
                />
              </div>
              <span className="truncate text-xs font-semibold text-[#1A1C1C]">
                {listing.seller.name}
              </span>
            </div>

            {listing.seller.verified && (
              <span className="flex items-center gap-1 text-[11px] font-medium text-[#00966B] bg-[#E8F5EE] px-2 py-0.5 rounded-full shrink-0">
                <CheckCircle2 className="h-3.5 w-3.5 fill-[#00966B] text-white" />
                Vérifié
              </span>
            )}
          </div>
        </div>
      </div>
    </article>
  );
}
