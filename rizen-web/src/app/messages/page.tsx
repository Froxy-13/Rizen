export const dynamic = "force-dynamic";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createServerClient } from "@supabase/ssr";
import { NavbarAuth } from "@/components/layout/NavbarAuth";
import { MessagesClient } from "@/components/ui/MessagesClient";
import { ConversationItem, ChatListing, ChatParticipant } from "@/types/chat";

const PLACEHOLDER_IMG =
  "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

function formatConvTime(iso: string): string {
  const date = new Date(iso);
  const now = new Date();
  const diffDays = Math.floor(
    (now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24)
  );
  if (diffDays === 0)
    return date.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });
  if (diffDays === 1) return "Hier";
  if (diffDays < 7)
    return date.toLocaleDateString("fr-FR", { weekday: "short" });
  return date.toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
}

type RawAnnonce = {
  id: number;
  titre: string;
  prix_actuel: number;
  ville: string | null;
  quartier: string | null;
  utilisateur_id: string;
  images_annonce: { url_image: string; ordre: number }[];
};

type RawProfil = {
  id: string;
  nom: string | null;
  prenom: string | null;
  photo: string | null;
};

export default async function MessagesPage({
  searchParams,
}: {
  searchParams: { conv?: string };
}) {
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
  if (!user) redirect("/auth/login?redirect=/messages");

  // 1. Profil navbar + IDs conversations de l'utilisateur
  const [{ data: profil }, { data: participations }] = await Promise.all([
    supabase
      .from("profils")
      .select("prenom, photo")
      .eq("id", user.id)
      .maybeSingle(),
    supabase
      .from("conversation_participants")
      .select("conversation_id")
      .eq("utilisateur_id", user.id),
  ]);

  const convIds = (participations ?? []).map((p) => p.conversation_id);

  if (convIds.length === 0) {
    return (
      <div className="h-dvh flex flex-col bg-[#FAF9F9] font-[Plus_Jakarta_Sans,sans-serif] overflow-hidden">
        <NavbarAuth prenom={profil?.prenom} photo={profil?.photo} />
        <main className="flex-1 min-h-0 flex justify-center py-4 px-4 md:px-6 overflow-hidden">
          <MessagesClient
            currentUserId={user.id}
            conversations={[]}
            initialSelectedId={null}
          />
        </main>
      </div>
    );
  }

  // 2. Conversations + autres participants + derniers messages (parallèle)
  const [
    { data: rawConvs },
    { data: otherParts },
    { data: lastMsgs },
  ] = await Promise.all([
    supabase
      .from("conversations")
      .select(
        "id, date_creation, annonces!inner(id, titre, prix_actuel, ville, quartier, utilisateur_id, images_annonce(url_image, ordre))"
      )
      .in("id", convIds),
    // Participants des mêmes conversations SAUF l'utilisateur courant
    supabase
      .from("conversation_participants")
      .select("conversation_id, utilisateur_id")
      .in("conversation_id", convIds)
      .neq("utilisateur_id", user.id),
    // Dernier message par conversation
    supabase
      .from("messages")
      .select("conversation_id, contenu, date_envoi")
      .in("conversation_id", convIds)
      .order("date_envoi", { ascending: false }),
  ]);

  // 3. Profils des autres participants
  const otherUserIds = Array.from(
    new Set((otherParts ?? []).map((p) => p.utilisateur_id))
  );
  const { data: partProfils } = otherUserIds.length > 0
    ? await supabase
        .from("profils")
        .select("id, nom, prenom, photo")
        .in("id", otherUserIds)
    : { data: [] as RawProfil[] };

  // Dernier message par conversation_id
  const lastMsgMap = new Map<number, { contenu: string; date_envoi: string }>();
  (lastMsgs ?? []).forEach((m) => {
    if (!lastMsgMap.has(m.conversation_id))
      lastMsgMap.set(m.conversation_id, m);
  });

  // 4. Construire ConversationItem[] et trier par dernière activité (plus récent en premier)
  const conversations: ConversationItem[] = (rawConvs ?? []).map((c) => {
    const annonce = c.annonces as unknown as RawAnnonce;

    // Autre participant de cette conversation
    const otherUserId = (otherParts ?? []).find(
      (p) => p.conversation_id === c.id
    )?.utilisateur_id;
    const p = (partProfils as RawProfil[] | null)?.find(
      (x) => x.id === otherUserId
    );

    const lastMsg = lastMsgMap.get(c.id);
    const imgs = (annonce?.images_annonce ?? []).sort(
      (a, b) => (a.ordre ?? 0) - (b.ordre ?? 0)
    );

    const listing: ChatListing = {
      id: String(annonce?.id ?? c.id),
      title: annonce?.titre ?? "Annonce supprimée",
      price: annonce?.prix_actuel ?? 0,
      location:
        [annonce?.quartier, annonce?.ville].filter(Boolean).join(", ") || "Dakar",
      image: imgs[0]?.url_image ?? PLACEHOLDER_IMG,
      url: `/annonces/${annonce?.id ?? ""}`,
    };

    const participant: ChatParticipant = {
      id: otherUserId ?? "",
      name: [p?.prenom, p?.nom].filter(Boolean).join(" ") || "Utilisateur",
      avatar: p?.photo ?? undefined,
      initials: (p?.prenom?.[0] ?? "U").toUpperCase(),
      verified: false,
      statusText: "Membre Rizen",
      online: false,
    };

    // Type : vendeur si l'utilisateur courant est propriétaire de l'annonce
    const isVendeur = annonce?.utilisateur_id === user.id;

    return {
      id: String(c.id),
      user: participant,
      listing,
      listingTitle: listing.title,
      lastMessage: lastMsg?.contenu ?? "Aucun message",
      timestamp: lastMsg ? formatConvTime(lastMsg.date_envoi) : "",
      type: isVendeur ? "vente" : "achat",
      _lastMsgDate: lastMsg?.date_envoi ?? c.date_creation,
    };
  }).sort((a, b) =>
    new Date((b as typeof a & { _lastMsgDate: string })._lastMsgDate).getTime() -
    new Date((a as typeof a & { _lastMsgDate: string })._lastMsgDate).getTime()
  ).map(({ ...conv }) => conv as ConversationItem);

  // Pas d'auto-sélection — uniquement si ?conv= est explicitement dans l'URL
  const initialSelectedId = searchParams.conv ?? null;

  return (
    <div className="h-dvh flex flex-col bg-[#FAF9F9] font-[Plus_Jakarta_Sans,sans-serif] overflow-hidden">
      <NavbarAuth prenom={profil?.prenom} photo={profil?.photo} />
      <main className="flex-1 min-h-0 flex justify-center py-4 px-4 md:px-6 overflow-hidden">
        <MessagesClient
          currentUserId={user.id}
          conversations={conversations}
          initialSelectedId={initialSelectedId}
        />
      </main>
    </div>
  );
}
