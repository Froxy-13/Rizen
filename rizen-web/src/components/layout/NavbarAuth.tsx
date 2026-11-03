"use client";

import React, { useState, useRef, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  Bell, PlusCircle, ChevronDown, User, Package, Heart,
  MessageSquare, Settings, LogOut, Menu, X,
  Compass, Search,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useRouter } from "next/navigation";

interface NavbarAuthProps {
  prenom?: string | null;
  photo?: string | null;
}

const navLinks = [
  { href: "/feed",      label: "Explorer",   icon: Compass },
  { href: "/decouvrir", label: "Découvrir",  icon: Search },
  { href: "/messages",  label: "Messages",   icon: MessageSquare },
];

const dropdownLinks = [
  { href: "/profil",              label: "Mon profil",     icon: User },
  { href: "/profil?tab=annonces", label: "Mes annonces",   icon: Package },
  { href: "/profil?tab=favoris",  label: "Mes favoris",    icon: Heart },
  { href: "/parametres",          label: "Paramètres",     icon: Settings },
];

export function NavbarAuth({ prenom, photo }: NavbarAuthProps) {
  const [dropdownOpen, setDropdownOpen]     = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [unreadCount, setUnreadCount]       = useState(0);
  const dropdownRef  = useRef<HTMLDivElement>(null);
  const router   = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    async function fetchUnread() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const { data: parts } = await supabase
        .from("conversation_participants")
        .select("conversation_id")
        .eq("utilisateur_id", user.id);
      const convIds = (parts ?? []).map((p) => p.conversation_id);
      if (convIds.length === 0) return;
      const { data: msgs } = await supabase
        .from("messages")
        .select("conversation_id")
        .in("conversation_id", convIds)
        .neq("sender_id", user.id)
        .eq("lu", false);
      setUnreadCount((msgs ?? []).length);
    }
    fetchUnread();

    // Mise à jour temps réel depuis MessagesClient (page /messages)
    const handler = (e: Event) => {
      setUnreadCount((e as CustomEvent<number>).detail);
    };
    window.addEventListener("unread-count-changed", handler);
    return () => window.removeEventListener("unread-count-changed", handler);
  }, []);

  // Close desktop dropdown on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  // Close mobile menu on route change
  useEffect(() => { setMobileMenuOpen(false); }, [pathname]);

  // Prevent body scroll when mobile menu is open
  useEffect(() => {
    document.body.style.overflow = mobileMenuOpen ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [mobileMenuOpen]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setMobileMenuOpen(false);
    router.refresh();
    router.push("/auth/login");
  };

  const initiale = prenom ? prenom[0].toUpperCase() : "?";

  return (
    <>
      <header className="sticky top-0 z-50 h-[68px] w-full bg-[#131B2D] shadow-[0_2px_20px_rgba(19,27,45,0.15)]">
        <div
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(circle at 92% 50%, rgba(252,113,56,0.15), transparent 55%)" }}
        />

        <div className="mx-auto flex h-full max-w-[1280px] items-center justify-between px-4 sm:px-6 relative z-10">
          {/* Gauche */}
          <div className="flex items-center gap-3">
            <Link href="/feed" className="flex items-center">
              <Image src="/Rizen.png" alt="Rizen" width={96} height={32} className="h-7 w-auto object-contain" priority />
            </Link>
            {/* Desktop nav */}
            <nav className="ml-6 hidden md:flex items-center gap-5 text-sm font-medium">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`relative flex items-center gap-1.5 transition-colors ${
                    pathname === link.href ? "text-[#FC7138] font-semibold" : "text-white/80 hover:text-[#FC7138]"
                  }`}
                >
                  {link.label}
                  {link.href === "/messages" && unreadCount > 0 && (
                    <span className={`flex h-4 w-4 items-center justify-center rounded-full text-[9px] font-bold ${
                      pathname === link.href ? "bg-white text-[#FC7138]" : "bg-[#FC7138] text-white"
                    }`}>
                      {unreadCount > 9 ? "9+" : unreadCount}
                    </span>
                  )}
                </Link>
              ))}
            </nav>
          </div>

          {/* Droite */}
          <div className="flex items-center gap-2 sm:gap-3">
            <Link
              href="/annonces/creer"
              className="flex items-center gap-1.5 rounded-full bg-[#FC7138] px-4 py-2 sm:px-5 sm:py-2.5 text-sm font-semibold text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] active:scale-95 transition-all"
            >
              <PlusCircle className="h-4 w-4 shrink-0" />
              <span className="hidden sm:inline">Vendre</span>
            </Link>

            {/* Cloche — desktop seulement */}
            <Link
              href="/notifications"
              className="relative hidden sm:flex h-10 w-10 items-center justify-center rounded-full text-white/85 hover:bg-white/10 transition-colors"
            >
              <Bell className="h-5 w-5" />
              <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-[#FC7138] ring-2 ring-[#131B2D]" />
            </Link>

            {/* Avatar dropdown — desktop */}
            <div className="relative hidden md:block" ref={dropdownRef}>
              <button
                onClick={() => setDropdownOpen(!dropdownOpen)}
                className="flex items-center gap-2 rounded-full p-1 pl-1.5 hover:bg-white/10 transition-colors"
                aria-label="Menu profil"
              >
                <div className="relative h-9 w-9 rounded-full ring-2 ring-white/80 overflow-hidden bg-[#FFDBBF] flex items-center justify-center shrink-0">
                  {photo
                    ? <Image src={photo} alt={prenom ?? "Profil"} fill className="object-cover" />
                    : <span className="text-[#FC7138] font-bold text-sm">{initiale}</span>
                  }
                </div>
                <ChevronDown className={`h-4 w-4 text-white/70 transition-transform ${dropdownOpen ? "rotate-180" : ""}`} />
              </button>

              {dropdownOpen && (
                <div className="absolute right-0 top-[calc(100%+8px)] w-52 rounded-2xl bg-white shadow-[0_8px_30px_rgba(19,27,45,0.15)] border border-[#E3E2E2]/60 overflow-hidden py-1.5 z-50">
                  {prenom && (
                    <div className="px-4 py-2.5 border-b border-[#F4F3F3] mb-1">
                      <p className="text-xs text-[#76777D]">Connecté en tant que</p>
                      <p className="text-sm font-semibold text-[#131B2D]">{prenom}</p>
                    </div>
                  )}
                  {dropdownLinks.map(({ href, label, icon: Icon }) => (
                    <Link key={href} href={href} onClick={() => setDropdownOpen(false)}
                      className="flex items-center gap-3 px-4 py-2.5 text-sm text-[#1A1C1C] hover:bg-[#FFF7F4] hover:text-[#FC7138] transition-colors"
                    >
                      <Icon className="h-4 w-4 shrink-0" /> {label}
                    </Link>
                  ))}
                  <div className="border-t border-[#F4F3F3] my-1" />
                  <button onClick={handleLogout}
                    className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-[#BA1A1A] hover:bg-red-50 transition-colors"
                  >
                    <LogOut className="h-4 w-4 shrink-0" /> Déconnexion
                  </button>
                </div>
              )}
            </div>

            {/* Hamburger — mobile uniquement */}
            <button
              className="md:hidden flex h-10 w-10 items-center justify-center rounded-full text-white hover:bg-white/10 transition-colors"
              onClick={() => setMobileMenuOpen((o) => !o)}
              aria-label="Ouvrir le menu"
            >
              {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </div>
      </header>

      {/* ── Menu mobile overlay ──────────────────────────────────────────── */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed inset-0 top-[68px] z-40 flex flex-col bg-[#131B2D]">
          {/* Profil */}
          <div className="flex items-center gap-3 px-5 py-4 border-b border-white/10">
            <div className="relative h-11 w-11 rounded-full ring-2 ring-white/40 overflow-hidden bg-[#FFDBBF] flex items-center justify-center shrink-0">
              {photo
                ? <Image src={photo} alt={prenom ?? "Profil"} fill className="object-cover" />
                : <span className="text-[#FC7138] font-bold">{initiale}</span>
              }
            </div>
            <div>
              <p className="text-sm font-bold text-white">{prenom ?? "Mon compte"}</p>
              <p className="text-xs text-white/50">Connecté</p>
            </div>
          </div>

          {/* Nav links */}
          <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
            {navLinks.map(({ href, label, icon: Icon }) => (
              <Link key={href} href={href}
                className={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition-colors ${
                  pathname === href
                    ? "bg-[#FC7138] text-white"
                    : "text-white/80 hover:bg-white/10 hover:text-white"
                }`}
              >
                <Icon className="h-5 w-5 shrink-0" />
                <span className="flex-1">{label}</span>
                {href === "/messages" && unreadCount > 0 && (
                  <span className={`flex h-5 min-w-[20px] items-center justify-center rounded-full px-1 text-[10px] font-bold ${
                    pathname === href ? "bg-white text-[#FC7138]" : "bg-[#FC7138] text-white"
                  }`}>
                    {unreadCount > 9 ? "9+" : unreadCount}
                  </span>
                )}
              </Link>
            ))}

            <div className="my-3 border-t border-white/10" />

            {dropdownLinks.map(({ href, label, icon: Icon }) => (
              <Link key={href} href={href}
                className="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-white/70 hover:bg-white/10 hover:text-white transition-colors"
              >
                <Icon className="h-4 w-4 shrink-0" /> {label}
              </Link>
            ))}
          </nav>

          {/* Bas : déconnexion */}
          <div className="px-3 py-4 border-t border-white/10">
            <button onClick={handleLogout}
              className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold text-red-400 hover:bg-white/10 transition-colors"
            >
              <LogOut className="h-4 w-4 shrink-0" /> Déconnexion
            </button>
          </div>
        </div>
      )}
    </>
  );
}
