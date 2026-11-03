"use client";

import React from "react";
import Image from "next/image";
import { Search } from "lucide-react";
import { ConversationItem } from "@/types/chat";

interface ChatSidebarProps {
  conversations: ConversationItem[];
  selectedId: string;
  onSelect: (id: string) => void;
  activeFilter: "all" | "achats" | "ventes";
  onFilterChange: (filter: "all" | "achats" | "ventes") => void;
  searchQuery: string;
  onSearchChange: (q: string) => void;
  totalUnread?: number;
  className?: string;
}

export function ChatSidebar({
  conversations,
  selectedId,
  onSelect,
  activeFilter,
  onFilterChange,
  searchQuery,
  onSearchChange,
  totalUnread = 0,
  className = "",
}: ChatSidebarProps) {
  const filtered = conversations.filter((c) => {
    const matchesFilter =
      activeFilter === "all" || c.type === (activeFilter === "achats" ? "achat" : "vente");
    const matchesSearch =
      !searchQuery ||
      c.user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.listingTitle.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  return (
    <aside className={`w-full lg:w-[380px] shrink-0 border-r border-[#E3E2E2] bg-white flex flex-col ${className}`}>
      {/* En-tête */}
      <div className="p-4 border-b border-[#F4F3F3]">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-black text-[#131B2D]">Messages</h1>
            {totalUnread > 0 && (
              <span className="rounded-full bg-[#FFF7F4] border border-[#FC7138]/20 px-2.5 py-0.5 text-xs font-bold text-[#FC7138]">
                {totalUnread} non {totalUnread > 1 ? "lus" : "lu"}
              </span>
            )}
          </div>
        </div>

        {/* Recherche */}
        <div className="mt-3 relative">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-[#76777D]" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Rechercher une conversation..."
            className="h-10 w-full rounded-full bg-[#F4F3F3] pl-10 pr-4 text-base md:text-xs text-[#1A1C1C] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all"
          />
        </div>

        {/* Filtres */}
        <div className="mt-3 flex items-center gap-2 text-xs font-bold">
          {(["all", "achats", "ventes"] as const).map((f) => (
            <button
              key={f}
              type="button"
              onClick={() => onFilterChange(f)}
              className={`px-3 py-1.5 rounded-full transition-all capitalize ${
                activeFilter === f
                  ? "bg-[#FC7138] text-white shadow-sm"
                  : "bg-transparent text-[#565E73] hover:bg-[#F4F3F3]"
              }`}
            >
              {f === "all" ? `Tous (${conversations.length})` : f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Liste */}
      <div className="flex-1 overflow-y-auto divide-y divide-[#F4F3F3]">
        {filtered.length === 0 ? (
          <div className="p-8 text-center text-xs text-[#76777D]">Aucune conversation trouvée</div>
        ) : (
          filtered.map((c) => {
            const isSelected = c.id === selectedId;
            return (
              <div
                key={c.id}
                onClick={() => onSelect(c.id)}
                role="button"
                tabIndex={0}
                onKeyDown={(e) => e.key === "Enter" && onSelect(c.id)}
                className={`relative flex items-start gap-3 p-4 cursor-pointer transition-all ${
                  isSelected ? "bg-[#FFF7F4]" : "bg-white hover:bg-[#FAF9F9]"
                }`}
              >
                {isSelected && (
                  <span className="absolute left-0 top-0 bottom-0 w-1 bg-[#FC7138] rounded-r" />
                )}

                {/* Avatar */}
                <div className="relative shrink-0">
                  {c.user.avatar ? (
                    <div className="relative h-12 w-12 overflow-hidden rounded-full">
                      <Image src={c.user.avatar} alt={c.user.name} fill className="object-cover" />
                    </div>
                  ) : (
                    <div className="flex h-12 w-12 items-center justify-center rounded-full bg-[#E8F1F5] text-sm font-bold text-[#131B2D]">
                      {c.user.initials ?? c.user.name.slice(0, 2).toUpperCase()}
                    </div>
                  )}
                  {c.user.online && (
                    <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-white bg-[#00966B]" />
                  )}
                </div>

                {/* Infos */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-baseline justify-between gap-1">
                    <h3 className="text-sm font-bold text-[#1A1C1C] truncate">{c.user.name}</h3>
                    <span className="text-[11px] text-[#76777D] shrink-0 font-medium">{c.timestamp}</span>
                  </div>
                  <p className="text-xs font-semibold text-[#131B2D] truncate mt-0.5">{c.listingTitle}</p>
                  <p className="text-xs text-[#565E73] truncate mt-0.5">{c.lastMessage}</p>
                </div>

                {Boolean(c.unreadCount) && (
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[#FC7138] text-[11px] font-bold text-white self-center">
                    {c.unreadCount}
                  </span>
                )}
              </div>
            );
          })
        )}
      </div>

    </aside>
  );
}
