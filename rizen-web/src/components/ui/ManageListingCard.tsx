"use client";

import React, { useState, useRef, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { MapPin, MoreVertical, ChevronRight, Pencil, Trash2 } from "lucide-react";
import { supabase } from "@/lib/supabase";

export interface ManagedListing {
  id: string;
  title: string;
  category: string;
  price: number;
  location: string;
  image: string;
  status: "active" | "suspendue" | "vendue";
}

const STATUS_LABELS: Record<ManagedListing["status"], { label: string; color: string; dot: string }> = {
  active:    { label: "En ligne",    color: "text-[#00966B]", dot: "bg-[#00966B]" },
  suspendue: { label: "Suspendue",   color: "text-[#76777D]", dot: "bg-[#76777D]" },
  vendue:    { label: "Vendue",      color: "text-[#FC7138]", dot: "bg-[#FC7138]" },
};

interface ManageListingCardProps {
  listing: ManagedListing;
  onDeleted?: (id: string) => void;
}

const PLACEHOLDER = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

export function ManageListingCard({ listing, onDeleted }: ManageListingCardProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const router = useRouter();

  const formattedPrice = `${listing.price.toLocaleString("fr-FR")} FCFA`;
  const badge = STATUS_LABELS[listing.status];

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  const handleSupprimer = async () => {
    setMenuOpen(false);
    if (!confirm("Supprimer définitivement cette annonce ?")) return;
    setLoading(true);
    await supabase.from("annonces").delete().eq("id", Number(listing.id));
    setLoading(false);
    onDeleted?.(listing.id);
    router.refresh();
  };

  return (
    <article className={`group relative flex flex-col rounded-2xl bg-white border border-[#E3E2E2]/60 overflow-hidden shadow-[0_4px_20px_rgba(19,27,45,0.05)] hover:shadow-[0_8px_30px_rgba(19,27,45,0.08)] transition-all ${loading ? "opacity-60 pointer-events-none" : ""}`}>
      {/* Image */}
      <div className="relative aspect-[4/3] w-full overflow-hidden bg-[#F4F3F3]">
        <Image
          src={listing.image || PLACEHOLDER}
          alt={listing.title}
          fill
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 25vw"
          className="object-cover transition-transform duration-300 group-hover:scale-105"
        />

        {/* Badge statut */}
        <span className={`absolute top-3 left-3 flex items-center gap-1.5 rounded-full bg-white/90 backdrop-blur-md px-3 py-1 text-xs font-semibold shadow-sm ${badge.color}`}>
          <span className={`h-2 w-2 rounded-full ${badge.dot}`} />
          {badge.label}
        </span>

        {/* Menu contextuel */}
        <div className="absolute top-3 right-3" ref={menuRef}>
          <button
            type="button"
            onClick={() => setMenuOpen(!menuOpen)}
            className="flex h-8 w-8 items-center justify-center rounded-full bg-[#131B2D]/70 backdrop-blur-sm text-white hover:bg-[#131B2D] transition-colors"
          >
            <MoreVertical className="h-4 w-4" />
          </button>

          {menuOpen && (
            <div className="absolute right-0 top-10 w-44 rounded-xl bg-white shadow-[0_8px_30px_rgba(19,27,45,0.12)] border border-[#E3E2E2]/60 overflow-hidden py-1 z-10">
              <Link
                href={`/annonces/${listing.id}/modifier`}
                className="flex items-center gap-2.5 px-4 py-2.5 text-sm text-[#1A1C1C] hover:bg-[#F4F3F3]"
                onClick={() => setMenuOpen(false)}
              >
                <Pencil className="h-3.5 w-3.5 text-[#565E73]" />
                Modifier
              </Link>
              <div className="border-t border-[#F4F3F3] my-0.5" />
              <button
                type="button"
                onClick={handleSupprimer}
                className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-[#BA1A1A] hover:bg-red-50"
              >
                <Trash2 className="h-3.5 w-3.5" />
                Supprimer
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Contenu */}
      <div className="flex flex-1 flex-col p-4 justify-between">
        <div>
          <span className="text-[11px] font-bold uppercase tracking-wider text-[#76777D]">
            {listing.category}
          </span>
          <h3 className="mt-1 text-sm font-bold text-[#1A1C1C] line-clamp-1 group-hover:text-[#FC7138] transition-colors">
            {listing.title}
          </h3>
          <div className="mt-1.5 text-base font-extrabold text-[#131B2D]">
            {formattedPrice}
          </div>
          <div className="mt-2 flex items-center gap-1 text-xs text-[#565E73]">
            <MapPin className="h-3.5 w-3.5 text-[#76777D] shrink-0" />
            <span className="truncate">{listing.location}</span>
          </div>
        </div>

        <div className="mt-4 pt-3 border-t border-[#F4F3F3] flex items-center justify-end">
          <Link
            href={`/annonces/${listing.id}`}
            className="flex items-center gap-0.5 text-xs font-bold text-[#FC7138] hover:underline"
          >
            Voir l&apos;annonce
            <ChevronRight className="h-3.5 w-3.5" />
          </Link>
        </div>
      </div>
    </article>
  );
}
