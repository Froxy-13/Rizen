"use client";

import React, { useState, useRef } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  Camera, ArrowLeft, Save, Loader2, CheckCircle2, AlertCircle, User, Phone, MapPin, FileText,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

interface ProfilData {
  id: string;
  prenom: string | null;
  nom: string | null;
  email: string | null;
  telephone: string | null;
  ville: string | null;
  bio: string | null;
  photo: string | null;
}

interface Props {
  profil: ProfilData;
}

const VILLES = [
  "Dakar", "Thiès", "Saint-Louis", "Ziguinchor", "Kaolack",
  "Mbour", "Rufisque", "Touba", "Diourbel", "Louga",
];

export function ModifierProfilClient({ profil }: Props) {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [prenom, setPrenom]       = useState(profil.prenom ?? "");
  const [nom, setNom]             = useState(profil.nom ?? "");
  const [telephone, setTelephone] = useState(profil.telephone ?? "");
  const [ville, setVille]         = useState(profil.ville ?? "");
  const [bio, setBio]             = useState(profil.bio ?? "");

  const [photoPreview, setPhotoPreview] = useState<string | null>(profil.photo ?? null);
  const [photoFile, setPhotoFile]       = useState<File | null>(null);

  const [saving, setSaving]   = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError]     = useState<string | null>(null);

  const initiale = (prenom[0] ?? profil.prenom?.[0] ?? "?").toUpperCase();
  const BIO_MAX = 300;

  // ── Photo selection ───────────────────────────────────────────────────────
  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      setError("La photo ne doit pas dépasser 5 Mo.");
      return;
    }
    setPhotoFile(file);
    setPhotoPreview(URL.createObjectURL(file));
    setError(null);
  };

  // ── Save ─────────────────────────────────────────────────────────────────
  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!prenom.trim() || !nom.trim()) {
      setError("Le prénom et le nom sont obligatoires.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      let photoUrl = profil.photo ?? null;

      // Upload photo si modifiée
      if (photoFile) {
        const ext = photoFile.name.split(".").pop();
        const path = `${profil.id}/avatar.${ext}`;
        const { error: uploadErr } = await supabase.storage
          .from("profils-photos")
          .upload(path, photoFile, { upsert: true, contentType: photoFile.type });
        if (uploadErr) throw new Error("Impossible d'uploader la photo.");
        const { data: urlData } = supabase.storage.from("profils-photos").getPublicUrl(path);
        photoUrl = `${urlData.publicUrl}?t=${Date.now()}`;
      }

      const { error: updateErr } = await supabase.from("profils").update({
        prenom: prenom.trim(),
        nom: nom.trim(),
        telephone: telephone.trim() || null,
        ville: ville.trim() || null,
        bio: bio.trim() || null,
        photo: photoUrl,
      }).eq("id", profil.id);

      if (updateErr) throw new Error("Impossible de sauvegarder les modifications.");

      setSuccess(true);
      setTimeout(() => router.push("/profil"), 1200);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Une erreur est survenue.");
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF9F9] font-[Plus_Jakarta_Sans,sans-serif]">
      <main className="mx-auto max-w-2xl px-4 sm:px-6 py-8 pb-20 space-y-6">

        {/* ── En-tête ───────────────────────────────────────────────────── */}
        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={() => router.back()}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-white border border-[#E3E2E2] text-[#565E73] hover:bg-[#F4F3F3] transition-colors shadow-sm"
          >
            <ArrowLeft className="h-4 w-4" />
          </button>
          <div>
            <h1 className="text-xl font-extrabold text-[#131B2D]">Modifier mon profil</h1>
            <p className="text-xs text-[#76777D] mt-0.5">Vos informations sont visibles par les acheteurs</p>
          </div>
        </div>

        {/* ── Photo de profil ───────────────────────────────────────────── */}
        <div className="bg-white rounded-2xl border border-[#E3E2E2] p-6 shadow-[0_2px_12px_rgba(19,27,45,0.05)]">
          <p className="text-sm font-bold text-[#131B2D] mb-4">Photo de profil</p>
          <div className="flex items-center gap-6">
            <div className="relative shrink-0">
              <div className="relative h-24 w-24 rounded-full overflow-hidden bg-[#FFDBBF] ring-4 ring-[#E3E2E2] flex items-center justify-center">
                {photoPreview ? (
                  <Image src={photoPreview} alt="Aperçu" fill className="object-cover" />
                ) : (
                  <span className="text-[#FC7138] text-3xl font-black">{initiale}</span>
                )}
              </div>
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="absolute -bottom-1 -right-1 flex h-8 w-8 items-center justify-center rounded-full bg-[#FC7138] text-white shadow-[0_4px_12px_rgba(252,113,56,0.35)] hover:bg-[#e05f29] transition-all active:scale-95"
              >
                <Camera className="h-3.5 w-3.5" />
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={handlePhotoChange}
              />
            </div>
            <div className="space-y-1.5">
              <p className="text-sm font-semibold text-[#1A1C1C]">
                {prenom || profil.prenom || "Votre nom"}
              </p>
              <p className="text-xs text-[#76777D]">JPG, PNG ou WebP · Max 5 Mo</p>
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="text-xs font-bold text-[#FC7138] hover:underline"
              >
                Changer la photo
              </button>
            </div>
          </div>
        </div>

        {/* ── Formulaire ────────────────────────────────────────────────── */}
        <form onSubmit={handleSave} className="space-y-5">

          {/* Identité */}
          <div className="bg-white rounded-2xl border border-[#E3E2E2] p-6 shadow-[0_2px_12px_rgba(19,27,45,0.05)] space-y-4">
            <div className="flex items-center gap-2 mb-1">
              <User className="h-4 w-4 text-[#FC7138]" />
              <p className="text-sm font-bold text-[#131B2D]">Identité</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-[#565E73] mb-1.5" htmlFor="prenom">
                  Prénom <span className="text-[#FC7138]">*</span>
                </label>
                <input
                  id="prenom"
                  type="text"
                  value={prenom}
                  onChange={(e) => setPrenom(e.target.value)}
                  placeholder="Votre prénom"
                  className="h-11 w-full rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 text-base md:text-sm text-[#1A1C1C] placeholder:text-[#BBBBBB] outline-none focus:border-[#FC7138] focus:ring-2 focus:ring-[#FC7138]/15 transition-all"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#565E73] mb-1.5" htmlFor="nom">
                  Nom <span className="text-[#FC7138]">*</span>
                </label>
                <input
                  id="nom"
                  type="text"
                  value={nom}
                  onChange={(e) => setNom(e.target.value)}
                  placeholder="Votre nom de famille"
                  className="h-11 w-full rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 text-base md:text-sm text-[#1A1C1C] placeholder:text-[#BBBBBB] outline-none focus:border-[#FC7138] focus:ring-2 focus:ring-[#FC7138]/15 transition-all"
                />
              </div>
            </div>

            {/* Email — lecture seule */}
            <div>
              <label className="block text-xs font-semibold text-[#565E73] mb-1.5">
                Adresse email
              </label>
              <div className="h-11 w-full rounded-xl border border-[#E3E2E2] bg-[#F4F3F3] px-4 flex items-center text-sm text-[#76777D] select-none">
                {profil.email ?? "—"}
              </div>
              <p className="mt-1 text-[11px] text-[#76777D]">L&apos;email ne peut pas être modifié ici.</p>
            </div>
          </div>

          {/* Coordonnées */}
          <div className="bg-white rounded-2xl border border-[#E3E2E2] p-6 shadow-[0_2px_12px_rgba(19,27,45,0.05)] space-y-4">
            <div className="flex items-center gap-2 mb-1">
              <Phone className="h-4 w-4 text-[#FC7138]" />
              <p className="text-sm font-bold text-[#131B2D]">Coordonnées</p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#565E73] mb-1.5" htmlFor="telephone">
                Téléphone
              </label>
              <input
                id="telephone"
                type="tel"
                value={telephone}
                onChange={(e) => setTelephone(e.target.value)}
                placeholder="+221 77 000 00 00"
                className="h-11 w-full rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 text-base md:text-sm text-[#1A1C1C] placeholder:text-[#BBBBBB] outline-none focus:border-[#FC7138] focus:ring-2 focus:ring-[#FC7138]/15 transition-all"
              />
              <p className="mt-1 text-[11px] text-[#76777D]">Visible uniquement après le début d&apos;une conversation.</p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#565E73] mb-1.5" htmlFor="ville">
                <span className="flex items-center gap-1.5">
                  <MapPin className="h-3 w-3" />
                  Ville principale
                </span>
              </label>
              <input
                id="ville"
                type="text"
                list="villes-list"
                value={ville}
                onChange={(e) => setVille(e.target.value)}
                placeholder="Ex : Dakar"
                className="h-11 w-full rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 text-base md:text-sm text-[#1A1C1C] placeholder:text-[#BBBBBB] outline-none focus:border-[#FC7138] focus:ring-2 focus:ring-[#FC7138]/15 transition-all"
              />
              <datalist id="villes-list">
                {VILLES.map((v) => <option key={v} value={v} />)}
              </datalist>
            </div>
          </div>

          {/* Présentation */}
          <div className="bg-white rounded-2xl border border-[#E3E2E2] p-6 shadow-[0_2px_12px_rgba(19,27,45,0.05)] space-y-4">
            <div className="flex items-center gap-2 mb-1">
              <FileText className="h-4 w-4 text-[#FC7138]" />
              <p className="text-sm font-bold text-[#131B2D]">Présentation</p>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-semibold text-[#565E73]" htmlFor="bio">
                  À propos de vous
                </label>
                <span className={`text-[11px] font-medium ${bio.length > BIO_MAX ? "text-[#BA1A1A]" : "text-[#76777D]"}`}>
                  {bio.length}/{BIO_MAX}
                </span>
              </div>
              <textarea
                id="bio"
                rows={4}
                value={bio}
                onChange={(e) => setBio(e.target.value.slice(0, BIO_MAX))}
                placeholder="Dites quelques mots sur vous, votre spécialité, ce que vous vendez…"
                className="w-full resize-none rounded-xl border border-[#E3E2E2] bg-[#FAF9F9] px-4 py-3 text-base md:text-sm text-[#1A1C1C] placeholder:text-[#BBBBBB] outline-none focus:border-[#FC7138] focus:ring-2 focus:ring-[#FC7138]/15 transition-all"
              />
            </div>
          </div>

          {/* Feedback */}
          {error && (
            <div className="flex items-start gap-3 rounded-xl bg-red-50 border border-red-100 px-4 py-3">
              <AlertCircle className="h-4 w-4 shrink-0 text-[#BA1A1A] mt-0.5" />
              <p className="text-xs font-semibold text-[#BA1A1A]">{error}</p>
            </div>
          )}

          {success && (
            <div className="flex items-center gap-3 rounded-xl bg-[#E8F5EE] border border-[#00966B]/20 px-4 py-3">
              <CheckCircle2 className="h-4 w-4 shrink-0 text-[#00966B]" />
              <p className="text-xs font-semibold text-[#00966B]">Profil mis à jour. Redirection…</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex gap-3 pt-1">
            <button
              type="button"
              onClick={() => router.back()}
              disabled={saving}
              className="flex h-12 flex-1 items-center justify-center rounded-full border border-[#E3E2E2] bg-white text-sm font-semibold text-[#565E73] hover:bg-[#F4F3F3] transition-all disabled:opacity-50"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={saving || success}
              className="flex h-12 flex-[2] items-center justify-center gap-2 rounded-full bg-[#FC7138] text-sm font-bold text-white shadow-[0_8px_24px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] active:scale-[0.99] transition-all disabled:opacity-60"
            >
              {saving ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : success ? (
                <CheckCircle2 className="h-4 w-4" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              {saving ? "Enregistrement…" : success ? "Enregistré" : "Enregistrer les modifications"}
            </button>
          </div>
        </form>
      </main>
    </div>
  );
}
