"use client";

import React, { useState, useRef, useCallback } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  Upload,
  X,
  ChevronRight,
  ChevronLeft,
  Check,
  Loader2,
  ImagePlus,
  AlertCircle,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { CreateListingHeader } from "@/components/layout/CreateListingHeader";

// ─── Types ────────────────────────────────────────────────────────────────────

interface Categorie {
  id: number;
  nom: string;
}

interface CreateListingClientProps {
  userId: string;
  prenom: string | null;
  photo: string | null;
  categories: Categorie[];
}

interface FormData {
  photos: File[];
  photosPreviews: string[];
  categorieId: number | null;
  categorieNom: string;
  titre: string;
  etat: string;
  description: string;
  prix: string;
  prixInitial: string;
  negociable: boolean;
  ville: string;
  quartier: string;
}

// ─── Constants ─────────────────────────────────────────────────────────────

const STEPS = [
  "Photos",
  "Catégorie",
  "Détails",
  "Prix",
  "Localisation",
  "Récapitulatif",
] as const;

const ETATS = [
  { value: "neuf", label: "Neuf", desc: "Jamais utilisé, emballage d'origine" },
  { value: "tres_bon", label: "Très bon état", desc: "Légèrement utilisé, aucun défaut visible" },
  { value: "bon", label: "Bon état", desc: "Utilisé avec de légères traces d'usure" },
  { value: "correct", label: "État correct", desc: "Fonctionnel avec des traces d'usure visibles" },
] as const;

const VILLES = [
  "Dakar", "Thiès", "Saint-Louis", "Ziguinchor", "Kaolack",
  "Mbour", "Touba", "Diourbel", "Tambacounda", "Rufisque",
];

const CAT_ICONS: Record<string, string> = {
  électronique: "smartphone",
  electronique: "smartphone",
  "vêtements": "apparel",
  vetements: "apparel",
  "vêtements & mode": "apparel",
  maison: "chair",
  "maison & décoration": "chair",
  véhicules: "two_wheeler",
  vehicules: "two_wheeler",
  sport: "fitness_center",
  beauté: "spa",
  beaute: "spa",
  immobilier: "apartment",
  livres: "menu_book",
  autres: "category",
};

function catIcon(nom: string) {
  return CAT_ICONS[nom.toLowerCase()] ?? "category";
}

// ─── Component ───────────────────────────────────────────────────────────────

export function CreateListingClient({
  userId,
  prenom,
  photo,
  categories,
}: CreateListingClientProps) {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [step, setStep] = useState(0); // 0-based index

  const [form, setForm] = useState<FormData>({
    photos: [],
    photosPreviews: [],
    categorieId: null,
    categorieNom: "",
    titre: "",
    etat: "",
    description: "",
    prix: "",
    prixInitial: "",
    negociable: false,
    ville: "Dakar",
    quartier: "",
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  // ── Photo handling ──────────────────────────────────────────────────────

  const handleFiles = useCallback(
    (files: FileList | null) => {
      if (!files) return;
      const newFiles = Array.from(files).slice(0, 8 - form.photos.length);
      const previews = newFiles.map((f) => URL.createObjectURL(f));
      setForm((prev) => ({
        ...prev,
        photos: [...prev.photos, ...newFiles],
        photosPreviews: [...prev.photosPreviews, ...previews],
      }));
    },
    [form.photos.length]
  );

  const removePhoto = (index: number) => {
    URL.revokeObjectURL(form.photosPreviews[index]);
    setForm((prev) => ({
      ...prev,
      photos: prev.photos.filter((_, i) => i !== index),
      photosPreviews: prev.photosPreviews.filter((_, i) => i !== index),
    }));
  };

  // ── Drag & drop ─────────────────────────────────────────────────────────

  const [dragOver, setDragOver] = useState(false);

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    handleFiles(e.dataTransfer.files);
  };

  // ── Validation ──────────────────────────────────────────────────────────

  const validateStep = (s: number): boolean => {
    const newErrors: Record<string, string> = {};
    if (s === 0 && form.photos.length === 0) {
      newErrors.photos = "Ajoutez au moins une photo.";
    }
    if (s === 1) {
      if (!form.categorieId) newErrors.categorie = "Choisissez une catégorie.";
      if (!form.titre.trim()) newErrors.titre = "Entrez un titre.";
      if (form.titre.length > 100) newErrors.titre = "Le titre doit faire moins de 100 caractères.";
    }
    if (s === 2) {
      if (!form.etat) newErrors.etat = "Choisissez un état.";
      if (form.description.trim().length < 20)
        newErrors.description = "La description doit faire au moins 20 caractères.";
    }
    if (s === 3) {
      const p = Number(form.prix.replace(/\s/g, ""));
      if (!form.prix || isNaN(p) || p < 500)
        newErrors.prix = "Entrez un prix valide (min. 500 FCFA).";
      if (form.negociable) {
        const pi = Number(form.prixInitial.replace(/\s/g, ""));
        if (!form.prixInitial || isNaN(pi) || pi < p)
          newErrors.prixInitial = "Le prix initial doit être ≥ au prix de vente.";
      }
    }
    if (s === 4) {
      if (!form.ville) newErrors.ville = "Choisissez une ville.";
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const goNext = () => {
    if (!validateStep(step)) return;
    setStep((s) => s + 1);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const goPrev = () => {
    setErrors({});
    setStep((s) => s - 1);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // ── Submit ──────────────────────────────────────────────────────────────

  const handleSubmit = async () => {
    if (!validateStep(4)) return;
    setSubmitting(true);
    setSubmitError(null);

    try {
      // 1. Upload photos (optional — fails gracefully if bucket not ready)
      const uploadedUrls: string[] = [];

      for (const file of form.photos) {
        try {
          const ext = file.name.split(".").pop() ?? "jpg";
          const path = `${userId}/${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`;

          const { error: uploadError } = await supabase.storage
            .from("annonces-images")
            .upload(path, file, { upsert: false });

          if (uploadError) {
            console.warn("Photo upload skipped:", uploadError.message);
            continue;
          }

          const { data: urlData } = supabase.storage
            .from("annonces-images")
            .getPublicUrl(path);

          uploadedUrls.push(urlData.publicUrl);
        } catch {
          console.warn("Photo upload error, continuing without this photo.");
        }
      }

      // 2. Insert annonce
      const prixActuel = Number(form.prix.replace(/\s/g, ""));
      const prixInitial = form.negociable
        ? Number(form.prixInitial.replace(/\s/g, ""))
        : prixActuel;

      const { data: annonce, error: insertError } = await supabase
        .from("annonces")
        .insert({
          titre: form.titre.trim(),
          description: form.description.trim(),
          prix_actuel: prixActuel,
          prix_initial: prixInitial,
          ville: form.ville,
          quartier: form.quartier.trim() || null,
          statut: "active",
          utilisateur_id: userId,
          categorie_id: form.categorieId,
          // etat sera actif après migration_v2.sql
          ...(form.etat ? { etat: form.etat } : {}),
          date_publication: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (insertError) throw new Error(insertError.message);

      // 3. Insert images (only if uploads succeeded)
      if (uploadedUrls.length > 0) {
        const imageRows = uploadedUrls.map((url, i) => ({
          annonce_id: annonce.id,
          url_image: url,
          ordre: i,
        }));

        const { error: imgError } = await supabase
          .from("images_annonce")
          .insert(imageRows);

        if (imgError) console.error("Images insert:", imgError.message);
      }

      // 4. Redirect
      router.push(`/annonces/${annonce.id}`);
    } catch (err) {
      setSubmitError(
        err instanceof Error ? err.message : "Une erreur est survenue. Réessayez."
      );
      setSubmitting(false);
    }
  };

  // ── Price formatting ────────────────────────────────────────────────────

  const formatPriceInput = (raw: string) => {
    const digits = raw.replace(/\D/g, "");
    return digits.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
  };

  // ── Render ──────────────────────────────────────────────────────────────

  return (
    <div className="min-h-screen bg-[#FAF9F9]">
      <CreateListingHeader prenom={prenom} photo={photo} />

      {/* Progress bar */}
      <div className="h-1 bg-[#E3E2E2]">
        <div
          className="h-full bg-[#FC7138] transition-all duration-500"
          style={{ width: `${((step + 1) / STEPS.length) * 100}%` }}
        />
      </div>

      <div className="mx-auto max-w-[720px] px-4 py-8 pb-28 md:px-6">
        {/* Step label */}
        <div className="mb-8 flex items-center gap-2">
          <span className="rounded-full bg-[#FC7138] px-3 py-1 text-xs font-bold text-white">
            {step + 1} / {STEPS.length}
          </span>
          <h2 className="text-xl font-extrabold text-[#131B2D]">{STEPS[step]}</h2>
        </div>

        {/* ── Step 0 : Photos ───────────────────────────────────────────── */}
        {step === 0 && (
          <div className="space-y-4">
            <p className="text-sm text-[#565E73]">
              Ajoutez jusqu&apos;à 8 photos. La première sera la photo principale.
            </p>

            {/* Drop zone */}
            {form.photos.length < 8 && (
              <div
                onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
                onDragLeave={() => setDragOver(false)}
                onDrop={handleDrop}
                onClick={() => fileInputRef.current?.click()}
                className={`flex flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed p-10 cursor-pointer transition-all ${
                  dragOver
                    ? "border-[#FC7138] bg-[#FFF7F4]"
                    : "border-[#E3E2E2] bg-white hover:border-[#FC7138]/40 hover:bg-[#FFF7F4]/50"
                }`}
              >
                <div className="flex h-14 w-14 items-center justify-center rounded-full bg-[#F4F3F3]">
                  <ImagePlus className="h-6 w-6 text-[#FC7138]" />
                </div>
                <div className="text-center">
                  <p className="text-sm font-bold text-[#131B2D]">
                    Glissez vos photos ici
                  </p>
                  <p className="text-xs text-[#76777D] mt-0.5">
                    ou cliquez pour parcourir · JPG, PNG, WEBP
                  </p>
                </div>
                <input
                  ref={fileInputRef}
                  type="file"
                  multiple
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => handleFiles(e.target.files)}
                />
              </div>
            )}

            {/* Preview grid */}
            {form.photosPreviews.length > 0 && (
              <div className="grid grid-cols-3 gap-3 sm:grid-cols-4">
                {form.photosPreviews.map((src, i) => (
                  <div key={i} className="relative aspect-square">
                    <Image
                      src={src}
                      alt={`Photo ${i + 1}`}
                      fill
                      className="rounded-xl object-cover"
                    />
                    {i === 0 && (
                      <span className="absolute bottom-1.5 left-1.5 rounded-full bg-[#FC7138] px-2 py-0.5 text-[10px] font-bold text-white">
                        Principale
                      </span>
                    )}
                    <button
                      type="button"
                      onClick={() => removePhoto(i)}
                      className="absolute right-1.5 top-1.5 flex h-6 w-6 items-center justify-center rounded-full bg-[#131B2D]/70 text-white hover:bg-[#131B2D] transition-colors"
                    >
                      <X className="h-3.5 w-3.5" />
                    </button>
                  </div>
                ))}

                {form.photos.length < 8 && (
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="aspect-square rounded-xl border-2 border-dashed border-[#E3E2E2] flex items-center justify-center hover:border-[#FC7138]/40 hover:bg-[#FFF7F4] transition-all"
                  >
                    <Upload className="h-5 w-5 text-[#76777D]" />
                  </button>
                )}
              </div>
            )}

            {errors.photos && <FieldError msg={errors.photos} />}
          </div>
        )}

        {/* ── Step 1 : Catégorie + Titre ────────────────────────────────── */}
        {step === 1 && (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-bold text-[#131B2D] mb-3">
                Catégorie <span className="text-[#FC7138]">*</span>
              </label>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                {categories.map((cat) => {
                  const selected = form.categorieId === cat.id;
                  return (
                    <button
                      key={cat.id}
                      type="button"
                      onClick={() =>
                        setForm((p) => ({
                          ...p,
                          categorieId: cat.id,
                          categorieNom: cat.nom,
                        }))
                      }
                      className={`flex items-center gap-2.5 rounded-xl border p-3.5 text-left transition-all ${
                        selected
                          ? "border-[#FC7138] bg-[#FFF7F4] text-[#FC7138]"
                          : "border-[#E3E2E2] bg-white text-[#565E73] hover:border-[#FC7138]/40 hover:bg-[#FFF7F4]/50"
                      }`}
                    >
                      <span className={`material-symbols-outlined text-[18px] shrink-0 ${selected ? "text-[#FC7138]" : "text-[#76777D]"}`}>
                        {catIcon(cat.nom)}
                      </span>
                      <span className="text-xs font-semibold truncate">{cat.nom}</span>
                      {selected && <Check className="h-3.5 w-3.5 ml-auto shrink-0" />}
                    </button>
                  );
                })}
              </div>
              {errors.categorie && <FieldError msg={errors.categorie} />}
            </div>

            <div>
              <label htmlFor="titre" className="block text-sm font-bold text-[#131B2D] mb-2">
                Titre de l&apos;annonce <span className="text-[#FC7138]">*</span>
              </label>
              <input
                id="titre"
                type="text"
                value={form.titre}
                onChange={(e) => setForm((p) => ({ ...p, titre: e.target.value }))}
                placeholder="Ex : iPhone 14 Pro 128GB Space Black"
                maxLength={100}
                className={`w-full rounded-xl border px-4 py-3 text-sm text-[#131B2D] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all ${
                  errors.titre ? "border-red-400 bg-red-50" : "border-[#E3E2E2] bg-white"
                }`}
              />
              <div className="mt-1 flex justify-between items-center">
                {errors.titre ? (
                  <FieldError msg={errors.titre} />
                ) : (
                  <span />
                )}
                <span className="text-[11px] text-[#76777D]">{form.titre.length}/100</span>
              </div>
            </div>
          </div>
        )}

        {/* ── Step 2 : Détails ──────────────────────────────────────────── */}
        {step === 2 && (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-bold text-[#131B2D] mb-3">
                État <span className="text-[#FC7138]">*</span>
              </label>
              <div className="space-y-2">
                {ETATS.map((e) => {
                  const selected = form.etat === e.value;
                  return (
                    <button
                      key={e.value}
                      type="button"
                      onClick={() => setForm((p) => ({ ...p, etat: e.value }))}
                      className={`w-full flex items-center gap-3 rounded-xl border p-4 text-left transition-all ${
                        selected
                          ? "border-[#FC7138] bg-[#FFF7F4]"
                          : "border-[#E3E2E2] bg-white hover:border-[#FC7138]/40"
                      }`}
                    >
                      <div
                        className={`h-5 w-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-all ${
                          selected ? "border-[#FC7138] bg-[#FC7138]" : "border-[#E3E2E2]"
                        }`}
                      >
                        {selected && <Check className="h-3 w-3 text-white" />}
                      </div>
                      <div>
                        <p className={`text-sm font-bold ${selected ? "text-[#FC7138]" : "text-[#131B2D]"}`}>
                          {e.label}
                        </p>
                        <p className="text-xs text-[#76777D] mt-0.5">{e.desc}</p>
                      </div>
                    </button>
                  );
                })}
              </div>
              {errors.etat && <FieldError msg={errors.etat} />}
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-bold text-[#131B2D] mb-2">
                Description <span className="text-[#FC7138]">*</span>
              </label>
              <textarea
                id="description"
                value={form.description}
                onChange={(e) => setForm((p) => ({ ...p, description: e.target.value }))}
                placeholder="Décrivez votre article : caractéristiques, défauts éventuels, raison de la vente..."
                rows={6}
                maxLength={2000}
                className={`w-full resize-none rounded-xl border px-4 py-3 text-sm text-[#131B2D] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all ${
                  errors.description ? "border-red-400 bg-red-50" : "border-[#E3E2E2] bg-white"
                }`}
              />
              <div className="mt-1 flex justify-between items-center">
                {errors.description ? (
                  <FieldError msg={errors.description} />
                ) : (
                  <span className="text-[11px] text-[#76777D]">Min. 20 caractères</span>
                )}
                <span className="text-[11px] text-[#76777D]">{form.description.length}/2000</span>
              </div>
            </div>
          </div>
        )}

        {/* ── Step 3 : Prix ─────────────────────────────────────────────── */}
        {step === 3 && (
          <div className="space-y-6">
            <div>
              <label htmlFor="prix" className="block text-sm font-bold text-[#131B2D] mb-2">
                Prix de vente (FCFA) <span className="text-[#FC7138]">*</span>
              </label>
              <div className="relative">
                <input
                  id="prix"
                  type="text"
                  inputMode="numeric"
                  value={form.prix}
                  onChange={(e) =>
                    setForm((p) => ({
                      ...p,
                      prix: formatPriceInput(e.target.value),
                    }))
                  }
                  placeholder="0"
                  className={`w-full rounded-xl border px-4 py-3 pr-16 text-sm text-[#131B2D] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all ${
                    errors.prix ? "border-red-400 bg-red-50" : "border-[#E3E2E2] bg-white"
                  }`}
                />
                <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-[#76777D]">
                  FCFA
                </span>
              </div>
              {errors.prix && <FieldError msg={errors.prix} />}
            </div>

            {/* Négociable toggle */}
            <button
              type="button"
              onClick={() => setForm((p) => ({ ...p, negociable: !p.negociable }))}
              className={`flex w-full items-center justify-between rounded-xl border p-4 transition-all ${
                form.negociable
                  ? "border-[#00966B] bg-[#E8F5EE]"
                  : "border-[#E3E2E2] bg-white hover:border-[#E3E2E2]"
              }`}
            >
              <div className="text-left">
                <p className="text-sm font-bold text-[#131B2D]">Prix négociable</p>
                <p className="text-xs text-[#76777D] mt-0.5">
                  Les acheteurs pourront vous faire une offre
                </p>
              </div>
              <div
                className={`h-6 w-11 rounded-full transition-all ${
                  form.negociable ? "bg-[#00966B]" : "bg-[#E3E2E2]"
                }`}
              >
                <div
                  style={{
                    transform: form.negociable ? "translateX(20px)" : "translateX(2px)",
                  }}
                  className="mt-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform"
                />
              </div>
            </button>

            {form.negociable && (
              <div>
                <label htmlFor="prixInitial" className="block text-sm font-bold text-[#131B2D] mb-2">
                  Prix initial (avant remise) <span className="text-[#FC7138]">*</span>
                </label>
                <div className="relative">
                  <input
                    id="prixInitial"
                    type="text"
                    inputMode="numeric"
                    value={form.prixInitial}
                    onChange={(e) =>
                      setForm((p) => ({
                        ...p,
                        prixInitial: formatPriceInput(e.target.value),
                      }))
                    }
                    placeholder="0"
                    className={`w-full rounded-xl border px-4 py-3 pr-16 text-sm text-[#131B2D] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all ${
                      errors.prixInitial ? "border-red-400 bg-red-50" : "border-[#E3E2E2] bg-white"
                    }`}
                  />
                  <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-[#76777D]">
                    FCFA
                  </span>
                </div>
                {errors.prixInitial && <FieldError msg={errors.prixInitial} />}
              </div>
            )}
          </div>
        )}

        {/* ── Step 4 : Localisation ─────────────────────────────────────── */}
        {step === 4 && (
          <div className="space-y-6">
            <div>
              <label htmlFor="ville" className="block text-sm font-bold text-[#131B2D] mb-2">
                Ville <span className="text-[#FC7138]">*</span>
              </label>
              <select
                id="ville"
                value={form.ville}
                onChange={(e) => setForm((p) => ({ ...p, ville: e.target.value }))}
                className={`w-full rounded-xl border px-4 py-3 text-sm text-[#131B2D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all bg-white ${
                  errors.ville ? "border-red-400" : "border-[#E3E2E2]"
                }`}
              >
                {VILLES.map((v) => (
                  <option key={v} value={v}>{v}</option>
                ))}
              </select>
              {errors.ville && <FieldError msg={errors.ville} />}
            </div>

            <div>
              <label htmlFor="quartier" className="block text-sm font-bold text-[#131B2D] mb-2">
                Quartier <span className="text-xs font-normal text-[#76777D]">(optionnel)</span>
              </label>
              <input
                id="quartier"
                type="text"
                value={form.quartier}
                onChange={(e) => setForm((p) => ({ ...p, quartier: e.target.value }))}
                placeholder="Ex : Plateau, Almadies, Mermoz..."
                className="w-full rounded-xl border border-[#E3E2E2] bg-white px-4 py-3 text-sm text-[#131B2D] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all"
              />
            </div>
          </div>
        )}

        {/* ── Step 5 : Récapitulatif ────────────────────────────────────── */}
        {step === 5 && (
          <div className="space-y-4">
            <p className="text-sm text-[#565E73]">
              Vérifiez les informations avant de publier votre annonce.
            </p>

            {/* Photo recap */}
            <RecapCard label="Photos">
              <div className="flex gap-2 flex-wrap">
                {form.photosPreviews.slice(0, 5).map((src, i) => (
                  <div key={i} className="relative h-14 w-14 rounded-lg overflow-hidden">
                    <Image src={src} alt="" fill className="object-cover" />
                  </div>
                ))}
                {form.photos.length > 5 && (
                  <div className="h-14 w-14 rounded-lg bg-[#F4F3F3] flex items-center justify-center text-xs font-bold text-[#565E73]">
                    +{form.photos.length - 5}
                  </div>
                )}
              </div>
            </RecapCard>

            <RecapCard label="Annonce">
              <p className="text-sm font-bold text-[#131B2D]">{form.titre}</p>
              <p className="text-xs text-[#565E73] mt-1">{form.categorieNom}</p>
            </RecapCard>

            <RecapCard label="État">
              <p className="text-sm font-semibold text-[#131B2D]">
                {ETATS.find((e) => e.value === form.etat)?.label}
              </p>
            </RecapCard>

            <RecapCard label="Description">
              <p className="text-xs text-[#565E73] line-clamp-3">{form.description}</p>
            </RecapCard>

            <RecapCard label="Prix">
              <p className="text-sm font-bold text-[#FC7138]">
                {Number(form.prix.replace(/\s/g, "")).toLocaleString("fr-FR")} FCFA
                {form.negociable && (
                  <span className="ml-2 text-xs font-semibold text-[#00966B]">Négociable</span>
                )}
              </p>
              {form.negociable && form.prixInitial && (
                <p className="text-xs text-[#76777D] mt-0.5 line-through">
                  {Number(form.prixInitial.replace(/\s/g, "")).toLocaleString("fr-FR")} FCFA
                </p>
              )}
            </RecapCard>

            <RecapCard label="Localisation">
              <p className="text-sm font-semibold text-[#131B2D]">
                {form.ville}{form.quartier ? ` · ${form.quartier}` : ""}
              </p>
            </RecapCard>

            {submitError && (
              <div className="flex items-start gap-2.5 rounded-xl bg-red-50 border border-red-200 p-4">
                <AlertCircle className="h-4 w-4 text-red-500 shrink-0 mt-0.5" />
                <p className="text-sm text-red-700">{submitError}</p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* ── Sticky action bar ─────────────────────────────────────────────── */}
      <div className="fixed bottom-0 left-0 right-0 z-30 border-t border-[#E3E2E2] bg-white px-4 py-4 shadow-[0_-4px_20px_rgba(19,27,45,0.08)]">
        <div className="mx-auto flex max-w-[720px] items-center justify-between gap-3">
          {step > 0 ? (
            <button
              type="button"
              onClick={goPrev}
              disabled={submitting}
              className="flex h-[48px] items-center gap-1.5 rounded-full border border-[#E3E2E2] px-5 text-sm font-bold text-[#131B2D] hover:bg-[#F4F3F3] transition-all disabled:opacity-50"
            >
              <ChevronLeft className="h-4 w-4" />
              Retour
            </button>
          ) : (
            <span />
          )}

          {step < STEPS.length - 1 ? (
            <button
              type="button"
              onClick={goNext}
              className="flex h-[48px] flex-1 items-center justify-center gap-2 rounded-full bg-[#FC7138] px-6 text-sm font-bold text-white shadow-[0_4px_16px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] transition-all active:scale-[0.99]"
            >
              Étape suivante
              <ChevronRight className="h-4 w-4" />
            </button>
          ) : (
            <button
              type="button"
              onClick={handleSubmit}
              disabled={submitting}
              className="flex h-[48px] flex-1 items-center justify-center gap-2 rounded-full bg-[#FC7138] px-6 text-sm font-bold text-white shadow-[0_4px_16px_rgba(252,113,56,0.25)] hover:bg-[#e05f29] transition-all active:scale-[0.99] disabled:opacity-60"
            >
              {submitting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Publication...
                </>
              ) : (
                <>
                  <Check className="h-4 w-4" />
                  Publier l&apos;annonce
                </>
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Small helpers ────────────────────────────────────────────────────────────

function FieldError({ msg }: { msg: string }) {
  return (
    <p className="mt-1.5 flex items-center gap-1.5 text-xs font-medium text-red-600">
      <AlertCircle className="h-3.5 w-3.5 shrink-0" />
      {msg}
    </p>
  );
}

function RecapCard({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-xl border border-[#E3E2E2] bg-white p-4">
      <p className="mb-2 text-[11px] font-bold uppercase tracking-wider text-[#76777D]">
        {label}
      </p>
      {children}
    </div>
  );
}
