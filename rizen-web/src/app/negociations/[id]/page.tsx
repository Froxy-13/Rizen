export const dynamic = "force-dynamic";

import React from "react";
import { notFound, redirect } from "next/navigation";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { NavbarAuth } from "@/components/layout/NavbarAuth";
import { NegociationClient } from "./NegociationClient";

const PLACEHOLDER = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

export default async function NegociationPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const cookieStore = await cookies();

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll(); },
        setAll() {},
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(`/auth/gate?redirect=/negociations/${id}`);

  const { data: profil } = await supabase
    .from("profils")
    .select("nom, prenom, photo")
    .eq("id", user.id)
    .maybeSingle();

  // ── Négociation principale ─────────────────────────────────────────────────
  const { data: rawNeg } = await supabase
    .from("negociations")
    .select(`
      id, prix_propose, date_proposition, statut, message, annonce_id, acheteur_id, vendeur_id, conversation_id,
      annonces!annonce_id (
        id, titre, prix_actuel, prix_initial, ville, quartier, etat,
        images_annonce ( url_image, ordre ),
        categories ( nom )
      ),
      acheteur:profils!acheteur_id ( id, nom, prenom, photo, note_moyenne, nombre_avis, certifie ),
      vendeur:profils!vendeur_id   ( id, nom, prenom, photo, note_moyenne, nombre_avis, certifie )
    `)
    .eq("id", Number(id))
    .maybeSingle();

  if (!rawNeg) notFound();

  // Sécurité : seuls l'acheteur et le vendeur peuvent voir
  const isAcheteur = rawNeg.acheteur_id === user.id;
  const isVendeur  = rawNeg.vendeur_id  === user.id;
  if (!isAcheteur && !isVendeur) notFound();

  // ── Historique des paliers (même annonce) ─────────────────────────────────
  const { data: rawHistory } = await supabase
    .from("negociations")
    .select("id, prix_propose, date_proposition, statut, message, acheteur_id, vendeur_id")
    .eq("annonce_id", rawNeg.annonce_id)
    .order("date_proposition", { ascending: true });

  // ── Types ─────────────────────────────────────────────────────────────────
  type Profil = { id: string; nom: string; prenom: string | null; photo: string | null; note_moyenne: number | null; nombre_avis: number; certifie: boolean };
  type AnnRaw = { id: number; titre: string; prix_actuel: number; prix_initial: number; ville: string | null; quartier: string | null; etat: string | null; images_annonce: { url_image: string; ordre: number }[]; categories: { nom: string } | null };
  type NegRaw = typeof rawNeg & { annonces: AnnRaw | null; acheteur: Profil | null; vendeur: Profil | null };

  const neg = rawNeg as unknown as NegRaw;

  // ── Annonce ───────────────────────────────────────────────────────────────
  const ann = neg.annonces;
  const imgs = (ann?.images_annonce ?? []).sort((a, b) => (a.ordre ?? 0) - (b.ordre ?? 0));

  const annonce = ann ? {
    id: ann.id,
    titre: ann.titre,
    prix_actuel: ann.prix_actuel,
    prix_initial: ann.prix_initial,
    etat: ann.etat,
    ville: ann.ville,
    quartier: ann.quartier,
    categorieNom: ann.categories?.nom ?? null,
    imageUrl: imgs[0]?.url_image ?? PLACEHOLDER,
  } : null;

  // ── Profils ───────────────────────────────────────────────────────────────
  const mapProfil = (p: Profil | null) => p ? {
    id: p.id,
    nom: p.nom,
    prenom: p.prenom,
    photo: p.photo,
    noteMoyenne: p.note_moyenne,
    nombreAvis: p.nombre_avis,
    certifie: p.certifie,
  } : null;

  const acheteurData = mapProfil(neg.acheteur);
  const vendeurData  = mapProfil(neg.vendeur);

  // ── Historique ────────────────────────────────────────────────────────────
  const history = (rawHistory ?? []).map((h) => ({
    id: h.id,
    prix_propose: h.prix_propose,
    date_proposition: h.date_proposition,
    statut: h.statut,
    message: h.message,
    isAcheteur: h.acheteur_id === user.id,
    isCurrent: h.id === Number(id),
  }));

  return (
    <div className="min-h-screen bg-[#FAF9F9]">
      <NavbarAuth prenom={profil?.prenom} photo={profil?.photo} />

      <NegociationClient
        negId={Number(id)}
        statut={neg.statut}
        prixPropose={neg.prix_propose}
        message={neg.message ?? null}
        dateProposition={neg.date_proposition}
        role={isAcheteur ? "acheteur" : "vendeur"}
        currentUserId={user.id}
        annonce={annonce}
        acheteur={acheteurData}
        vendeur={vendeurData}
        history={history}
      />
    </div>
  );
}
