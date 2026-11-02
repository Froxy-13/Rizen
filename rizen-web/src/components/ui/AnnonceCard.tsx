"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Heart, MapPin, Star } from "lucide-react";
import { Annonce } from "@/types";

interface AnnonceCardProps {
  annonce: Annonce;
  isFavori?: boolean;
  onToggleFavori?: (id: number) => void;
}

export default function AnnonceCard({
  annonce,
  isFavori = false,
  onToggleFavori,
}: AnnonceCardProps) {
  const [favori, setFavori] = useState(isFavori);
  const image = annonce.images_annonce?.[0]?.url_image;

  const handleFavori = (e: React.MouseEvent) => {
    e.preventDefault();
    setFavori(!favori);
    onToggleFavori?.(annonce.id);
  };

  const formatPrix = (prix: number) =>
    new Intl.NumberFormat("fr-SN").format(prix) + " FCFA";

  const timeAgo = (date: string) => {
    const diff = Date.now() - new Date(date).getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    if (days === 0) return "Aujourd'hui";
    if (days === 1) return "Hier";
    if (days < 7) return `Il y a ${days} jours`;
    return new Date(date).toLocaleDateString("fr-SN", { day: "numeric", month: "short" });
  };

  return (
    <Link href={`/annonces/${annonce.id}`}>
      <article className="card-hover group overflow-hidden cursor-pointer">
        {/* Image */}
        <div className="relative aspect-[4/3] bg-rizen-surface-low overflow-hidden rounded-t-xl">
          {image ? (
            <Image
              src={image}
              alt={annonce.titre}
              fill
              className="object-cover transition-transform duration-300 group-hover:scale-105"
              sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-rizen-muted">
              <span className="text-4xl">📦</span>
            </div>
          )}

          {/* Prix badge */}
          <div className="absolute bottom-3 left-3">
            <span className="badge-navy text-sm font-bold px-3 py-1.5 rounded-full bg-navy text-white">
              {formatPrix(annonce.prix_actuel)}
            </span>
          </div>

          {/* Favori */}
          <button
            onClick={handleFavori}
            className="absolute top-3 right-3 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center transition-transform duration-150 hover:scale-110 active:scale-95"
            aria-label={favori ? "Retirer des favoris" : "Ajouter aux favoris"}
          >
            <Heart
              className={`w-4 h-4 transition-colors ${
                favori ? "fill-primary text-primary" : "text-rizen-muted"
              }`}
            />
          </button>
        </div>

        {/* Contenu */}
        <div className="p-4 space-y-2">
          <h3 className="font-semibold text-rizen-on-surface text-sm leading-snug line-clamp-2">
            {annonce.titre}
          </h3>

          <div className="flex items-center gap-1 text-rizen-muted text-xs">
            <MapPin className="w-3 h-3 flex-shrink-0" />
            <span>
              {[annonce.ville, annonce.quartier].filter(Boolean).join(" · ")}
            </span>
          </div>

          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 rounded-full bg-rizen-surface-low flex items-center justify-center text-[10px] font-bold text-navy overflow-hidden">
                {annonce.profils?.photo ? (
                  <Image
                    src={annonce.profils.photo}
                    alt=""
                    width={24}
                    height={24}
                    className="object-cover"
                  />
                ) : (
                  (annonce.profils?.prenom?.[0] ?? "?").toUpperCase()
                )}
              </div>
              <span className="text-xs text-rizen-muted">
                {annonce.profils?.prenom ?? "Vendeur"}
              </span>
            </div>
            <span className="text-xs text-rizen-muted">
              {timeAgo(annonce.date_publication)}
            </span>
          </div>
        </div>
      </article>
    </Link>
  );
}
