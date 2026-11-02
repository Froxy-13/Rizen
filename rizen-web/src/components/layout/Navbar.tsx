"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Menu, X, Plus } from "lucide-react";
import Button from "@/components/ui/Button";

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navLinks = [
    { href: "/", label: "Accueil" },
    { href: "/decouvrir", label: "Découvrir" },
    { href: "/comment-ca-marche", label: "Comment ça marche" },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled
          ? "bg-navy shadow-nav"
          : "bg-transparent"
      }`}
    >
      <nav className="container-rizen h-16 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 group">
          <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white font-bold text-sm transition-transform group-hover:scale-105">
            R
          </div>
          <span className="font-bold text-white text-lg tracking-tight">Rizen</span>
        </Link>

        {/* Nav links — desktop */}
        <div className="hidden md:flex items-center gap-1">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                pathname === link.href
                  ? "text-primary"
                  : "text-white/70 hover:text-white"
              }`}
            >
              {link.label}
            </Link>
          ))}
        </div>

        {/* Actions — desktop */}
        <div className="hidden md:flex items-center gap-3">
          <Link
            href="/auth/login"
            className="text-white/80 hover:text-white text-sm font-medium transition-colors px-3 py-2"
          >
            Se connecter
          </Link>
          <Link href="/annonces/creer">
            <Button size="sm" className="gap-1.5">
              <Plus className="w-4 h-4" />
              Publier une annonce
            </Button>
          </Link>
        </div>

        {/* Burger — mobile */}
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="md:hidden text-white p-2"
          aria-label="Menu"
        >
          {menuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </nav>

      {/* Menu mobile */}
      {menuOpen && (
        <div className="md:hidden bg-navy border-t border-white/10 px-4 pb-6 pt-4 space-y-2">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              onClick={() => setMenuOpen(false)}
              className={`block px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                pathname === link.href
                  ? "text-primary bg-primary/10"
                  : "text-white/80 hover:text-white hover:bg-white/5"
              }`}
            >
              {link.label}
            </Link>
          ))}
          <div className="pt-2 space-y-2">
            <Link href="/auth/login" onClick={() => setMenuOpen(false)}>
              <Button variant="secondary" fullWidth>Se connecter</Button>
            </Link>
            <Link href="/annonces/creer" onClick={() => setMenuOpen(false)}>
              <Button fullWidth>
                <Plus className="w-4 h-4" />
                Publier une annonce
              </Button>
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
