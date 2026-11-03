export const dynamic = "force-dynamic";

import React from "react";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { NavbarDecouvrir } from "@/components/layout/NavbarDecouvrir";
import { VendeurProfileClient } from "./VendeurProfileClient";

export default async function VendeurProfilPage({
  params,
}: {
  params: Promise<{ vendeurId: string }>;
}) {
  const { vendeurId } = await params;
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

  const { data: profil } = await supabase
    .from("profils")
    .select("id, nom, prenom, photo, bio, ville, certifie, note_moyenne, nombre_avis, nombre_ventes, date_inscription, created_at")
    .eq("id", vendeurId)
    .maybeSingle();

  if (!profil) notFound();

  const [{ data: annonces }, { data: avisData }] = await Promise.all([
    supabase
      .from("annonces")
      .select("id, titre, prix_actuel, prix_initial, ville, quartier, date_publication, images_annonce(url_image, ordre)")
      .eq("utilisateur_id", vendeurId)
      .eq("statut", "active")
      .order("date_publication", { ascending: false }),

    supabase
      .from("avis")
      .select("note, commentaire, date_avis, profils:acheteur_id(nom, prenom, photo)")
      .eq("vendeur_id", vendeurId)
      .order("date_avis", { ascending: false })
      .limit(20),
  ]);

  const PLACEHOLDER_IMG = "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

  type AnnoncesRaw = {
    id: number;
    titre: string;
    prix_actuel: number;
    prix_initial: number;
    ville: string | null;
    quartier: string | null;
    date_publication: string;
    images_annonce: { url_image: string; ordre: number }[];
  };

  const listingsForClient = (annonces ?? []).map((a: AnnoncesRaw) => {
    const imgs = (a.images_annonce ?? []).sort((x, y) => (x.ordre ?? 0) - (y.ordre ?? 0));
    return {
      id: a.id,
      titre: a.titre,
      prix_actuel: a.prix_actuel,
      prix_initial: a.prix_initial,
      ville: a.ville,
      quartier: a.quartier,
      date_publication: a.date_publication,
      imageUrl: imgs[0]?.url_image ?? PLACEHOLDER_IMG,
    };
  });

  type AvisRaw = {
    note: number;
    commentaire: string | null;
    date_avis: string;
    profils: { nom: string; prenom: string | null; photo: string | null } | null;
  };

  const avisForClient = ((avisData ?? []) as unknown as AvisRaw[]).map((a) => ({
    note: a.note,
    commentaire: a.commentaire,
    date_avis: a.date_avis,
    acheteur: a.profils,
  }));

  const noteMoyenne =
    profil.note_moyenne ??
    (avisForClient.length > 0
      ? Math.round((avisForClient.reduce((s, a) => s + a.note, 0) / avisForClient.length) * 10) / 10
      : null);

  return (
    <div className="min-h-screen bg-[#FAF9F9]">
      <NavbarDecouvrir />
      <VendeurProfileClient
        vendeurId={vendeurId}
        nom={profil.nom}
        prenom={profil.prenom ?? null}
        photo={profil.photo ?? null}
        bio={profil.bio ?? null}
        ville={profil.ville ?? null}
        certifie={profil.certifie ?? false}
        noteMoyenne={noteMoyenne}
        nombreAvis={profil.nombre_avis ?? avisForClient.length}
        nombreVentes={profil.nombre_ventes ?? 0}
        dateInscription={profil.date_inscription ?? profil.created_at}
        annonces={listingsForClient}
        avis={avisForClient}
        currentUserId={user?.id ?? null}
        isOwnProfile={user?.id === vendeurId}
      />
    </div>
  );
}
