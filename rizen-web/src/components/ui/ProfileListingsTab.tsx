"use client";

import React, { useState } from "react";
import { SlidersHorizontal, Package } from "lucide-react";
import { ManageListingCard, ManagedListing } from "@/components/ui/ManageListingCard";

interface ProfileListingsTabProps {
  active: ManagedListing[];
  suspended: ManagedListing[];
  sold: ManagedListing[];
}

type Tab = "active" | "suspended" | "sold";

export function ProfileListingsTab({ active, suspended, sold }: ProfileListingsTabProps) {
  const [tab, setTab] = useState<Tab>("active");

  const listings = tab === "active" ? active : tab === "suspended" ? suspended : sold;

  const tabs: { key: Tab; label: string; count: number }[] = [
    { key: "active",    label: "Mes annonces",    count: active.length },
    { key: "suspended", label: "Suspendues",       count: suspended.length },
    { key: "sold",      label: "Vendues",          count: sold.length },
  ];

  return (
    <div className="space-y-6">
      {/* Onglets */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#E3E2E2] pb-3">
        <div className="flex items-center gap-6">
          {tabs.map(({ key, label, count }) => (
            <button
              key={key}
              type="button"
              onClick={() => setTab(key)}
              className={`relative pb-3 text-sm font-bold transition-colors ${
                tab === key ? "text-[#FC7138]" : "text-[#565E73] hover:text-[#131B2D]"
              }`}
            >
              {label}
              <span className={`ml-2 rounded-full px-2 py-0.5 text-xs ${
                tab === key
                  ? "bg-[#FFDBBF] text-[#FC7138]"
                  : "bg-[#F4F3F3] text-[#565E73]"
              }`}>
                {count}
              </span>
              {tab === key && (
                <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#FC7138] rounded-full" />
              )}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-2 text-xs font-semibold text-[#565E73]">
          <SlidersHorizontal className="h-3.5 w-3.5" />
          <span>Récentes en premier</span>
        </div>
      </div>

      {/* Grille */}
      {listings.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
          {listings.map((listing) => (
            <ManageListingCard key={listing.id} listing={listing} />
          ))}
        </div>
      ) : (
        <div className="py-16 flex flex-col items-center text-center">
          <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#F4F3F3] text-[#76777D]">
            <Package className="h-7 w-7" />
          </div>
          <h3 className="text-base font-bold text-[#131B2D]">Aucune annonce ici</h3>
          <p className="text-xs text-[#565E73] mt-1">
            {tab === "active" ? "Publiez votre première annonce." : "Aucune annonce dans cette catégorie."}
          </p>
        </div>
      )}

    </div>
  );
}
