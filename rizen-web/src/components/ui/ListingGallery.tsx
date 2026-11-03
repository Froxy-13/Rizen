"use client";

import React, { useState } from "react";
import Image from "next/image";
import { Heart, Share2, ChevronLeft, ChevronRight } from "lucide-react";

interface ListingGalleryProps {
  images: string[];
  title: string;
}

const PLACEHOLDER = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=1000&auto=format&fit=crop";

export function ListingGallery({ images, title }: ListingGalleryProps) {
  const imgs = images.length > 0 ? images : [PLACEHOLDER];
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [isFavorite, setIsFavorite] = useState(false);

  const handlePrev = () => setSelectedIndex((p) => (p === 0 ? imgs.length - 1 : p - 1));
  const handleNext = () => setSelectedIndex((p) => (p === imgs.length - 1 ? 0 : p + 1));

  const handleShare = async () => {
    if (navigator.share) {
      await navigator.share({ title, url: window.location.href });
    } else {
      await navigator.clipboard.writeText(window.location.href);
    }
  };

  return (
    <div className="space-y-4">
      {/* Photo principale */}
      <div className="relative h-[480px] w-full overflow-hidden rounded-2xl bg-[#F4F3F3] shadow-[0_4px_20px_rgba(19,27,45,0.06)]">
        <Image
          src={imgs[selectedIndex]}
          alt={`${title} — photo ${selectedIndex + 1}`}
          fill
          priority
          sizes="(max-width: 1024px) 100vw, 65vw"
          className="object-cover transition-all duration-300"
        />

        {/* Compteur */}
        <span className="absolute top-4 left-4 flex items-center gap-1 rounded-full bg-[#131B2D]/80 px-3 py-1 text-xs font-semibold text-white backdrop-blur-md">
          {selectedIndex + 1} / {imgs.length}
        </span>

        {/* Actions */}
        <div className="absolute top-4 right-4 flex items-center gap-2">
          <button
            type="button"
            onClick={() => setIsFavorite(!isFavorite)}
            aria-label="Favoris"
            className="flex h-10 w-10 items-center justify-center rounded-full bg-white/90 backdrop-blur-md shadow-md transition-transform hover:scale-105 active:scale-95"
          >
            <Heart
              className={`h-5 w-5 transition-colors ${
                isFavorite ? "fill-[#FC7138] text-[#FC7138]" : "text-[#131B2D]"
              }`}
            />
          </button>
          <button
            type="button"
            onClick={handleShare}
            aria-label="Partager"
            className="flex h-10 w-10 items-center justify-center rounded-full bg-white/90 backdrop-blur-md shadow-md transition-transform hover:scale-105 active:scale-95"
          >
            <Share2 className="h-5 w-5 text-[#131B2D]" />
          </button>
        </div>

        {/* Flèches */}
        {imgs.length > 1 && (
          <>
            <button
              type="button"
              onClick={handlePrev}
              aria-label="Image précédente"
              className="absolute left-4 top-1/2 -translate-y-1/2 flex h-9 w-9 items-center justify-center rounded-full bg-white/80 backdrop-blur-md shadow hover:bg-white transition-all"
            >
              <ChevronLeft className="h-5 w-5 text-[#131B2D]" />
            </button>
            <button
              type="button"
              onClick={handleNext}
              aria-label="Image suivante"
              className="absolute right-4 top-1/2 -translate-y-1/2 flex h-9 w-9 items-center justify-center rounded-full bg-white/80 backdrop-blur-md shadow hover:bg-white transition-all"
            >
              <ChevronRight className="h-5 w-5 text-[#131B2D]" />
            </button>
          </>
        )}
      </div>

      {/* Miniatures */}
      {imgs.length > 1 && (
        <div className="flex items-center gap-3 overflow-x-auto pb-1">
          {imgs.map((img, idx) => (
            <button
              key={idx}
              type="button"
              onClick={() => setSelectedIndex(idx)}
              className={`relative h-16 w-20 shrink-0 overflow-hidden rounded-xl border-2 transition-all ${
                idx === selectedIndex
                  ? "border-[#FC7138] ring-2 ring-[#FC7138]/20 scale-105"
                  : "border-transparent opacity-70 hover:opacity-100"
              }`}
            >
              <Image src={img} alt={`Miniature ${idx + 1}`} fill className="object-cover" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
