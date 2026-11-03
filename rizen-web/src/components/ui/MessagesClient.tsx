"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  MoreVertical,
  SendHorizontal,
  CheckCircle2,
  MessageSquareDashed,
  Loader2,
  TrendingDown,
  TrendingUp,
  X,
  Handshake,
  Check,
  XCircle,
  ArrowLeft,
  PanelLeftClose,
  CheckCheck,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { ChatSidebar } from "@/components/ui/ChatSidebar";
import { ChatListingBanner } from "@/components/ui/ChatListingBanner";
import { ConversationItem, ChatMessage, NegociationSummary } from "@/types/chat";

interface MessagesClientProps {
  currentUserId: string;
  conversations: ConversationItem[];
  initialSelectedId: string | null;
}

type DBMessage = {
  id: number;
  sender_id: string;
  contenu: string;
  date_envoi: string;
  lu: boolean;
  type?: string | null;
  negociation_id?: number | null;
};

type DBNeg = { id: number; prix_propose: number; statut: string };

function formatMsgTime(iso: string): string {
  return new Date(iso).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });
}

const PLACEHOLDER_IMG =
  "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&auto=format&fit=crop";

// ── Négociation card ──────────────────────────────────────────────────────────

const NEG_STATUS: Record<string, { label: string; bg: string; text: string }> = {
  en_attente: { label: "En attente", bg: "bg-[#FFF7F4]", text: "text-[#FC7138]" },
  acceptee:   { label: "Acceptée",   bg: "bg-[#E8F5EE]",  text: "text-[#00966B]" },
  refusee:    { label: "Refusée",    bg: "bg-[#FFF0F0]",  text: "text-[#BA1A1A]" },
  annulee:    { label: "Annulée",    bg: "bg-[#F4F3F3]",  text: "text-[#565E73]" },
};

function NegCard({
  msg,
  isAcheteur,
  originalPrice,
  onAccept,
  onCounter,
  onRefuse,
  onAcheter,
}: {
  msg: ChatMessage;
  isAcheteur: boolean;
  originalPrice: number;
  onAccept: (id: number) => void;
  onCounter: (id: number, prix: number) => void;
  onRefuse: (id: number) => void;
  onAcheter?: () => void;
}) {
  const d = msg.negociationData!;
  const cfg = NEG_STATUS[d.statut] ?? NEG_STATUS.en_attente;
  const isActive = d.statut === "en_attente";
  const isAccepted = d.statut === "acceptee";
  const hasDiscount = originalPrice > 0 && d.prixPropose < originalPrice;

  return (
    <div
      className={`rounded-2xl border overflow-hidden shadow-sm ${
        msg.isSelf
          ? "ml-auto border-[#FC7138]/30 bg-[#FFF7F4] max-w-[85%]"
          : "border-[#E3E2E2]/60 bg-white max-w-[85%]"
      }`}
    >
      <div className="px-4 pt-3 pb-2">
        <div className="flex items-center justify-between gap-2 mb-2">
          <span className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-[#76777D]">
            <TrendingDown className="h-3.5 w-3.5 text-[#FC7138]" />
            {msg.isSelf ? "Votre offre" : "Offre reçue"}
          </span>
          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${cfg.bg} ${cfg.text}`}>
            {cfg.label}
          </span>
        </div>

        {/* Prix original barré + prix négocié */}
        {hasDiscount && (
          <p className="text-xs font-semibold text-[#76777D] line-through mb-0.5">
            {originalPrice.toLocaleString("fr-FR")} FCFA
          </p>
        )}
        <p className="text-xl font-black tracking-tight text-[#131B2D]">
          {d.prixPropose.toLocaleString("fr-FR")}{" "}
          <span className="text-sm font-bold text-[#565E73]">FCFA</span>
          {hasDiscount && (
            <span className="ml-2 text-xs font-bold text-[#00966B]">
              -{Math.round(((originalPrice - d.prixPropose) / originalPrice) * 100)}%
            </span>
          )}
        </p>
        {msg.content && (
          <p className="mt-1 text-xs text-[#565E73] line-clamp-2 italic">{msg.content}</p>
        )}
      </div>

      {/* Actions pour le destinataire — offre active */}
      {!msg.isSelf && isActive && (
        <div className="border-t border-[#E3E2E2]/60 grid grid-cols-3 divide-x divide-[#E3E2E2]/60">
          <button
            onClick={() => onAccept(d.id)}
            className="py-2.5 text-[11px] font-bold text-[#00966B] hover:bg-[#E8F5EE] transition-colors flex items-center justify-center gap-1"
          >
            <Check className="h-3 w-3" />
            Accepter
          </button>
          <button
            onClick={() => onCounter(d.id, d.prixPropose)}
            className="py-2.5 text-[11px] font-bold text-[#FC7138] hover:bg-[#FFF7F4] transition-colors flex items-center justify-center gap-1"
          >
            <Handshake className="h-3 w-3" />
            Contre-proposer
          </button>
          <button
            onClick={() => onRefuse(d.id)}
            className="py-2.5 text-[11px] font-bold text-[#BA1A1A] hover:bg-[#FFF0F0] transition-colors flex items-center justify-center gap-1"
          >
            <XCircle className="h-3 w-3" />
            Refuser
          </button>
        </div>
      )}

      {/* Bouton Acheter — acheteur, offre acceptée (peu importe qui a envoyé ce message) */}
      {isAccepted && isAcheteur && onAcheter && (
        <div className="border-t border-[#00966B]/20 bg-[#E8F5EE] px-4 py-2.5">
          <button
            onClick={onAcheter}
            className="flex w-full items-center justify-center gap-2 rounded-full bg-[#FC7138] py-2 text-xs font-bold text-white shadow-sm hover:bg-[#e05f29] transition-all active:scale-[0.99]"
          >
            Passer à l&apos;achat
          </button>
        </div>
      )}

      <div className="px-4 pb-2 pt-1">
        <span className="text-[10px] text-[#76777D]">{msg.timestamp}</span>
      </div>
    </div>
  );
}

// ── Main component ────────────────────────────────────────────────────────────

export function MessagesClient({
  currentUserId,
  conversations,
  initialSelectedId,
}: MessagesClientProps) {
  const router = useRouter();
  const [selectedConvId, setSelectedConvId] = useState<string | null>(initialSelectedId);
  const [mobileView, setMobileView] = useState<"list" | "chat">(initialSelectedId ? "chat" : "list");
  const [ctxMenu, setCtxMenu] = useState<{ x: number; y: number } | null>(null);
  const [filter, setFilter] = useState<"all" | "achats" | "ventes">("all");
  const [search, setSearch] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loadingMsgs, setLoadingMsgs] = useState(false);
  const [inputMessage, setInputMessage] = useState("");
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // ── Offer modal (Faire une offre) ─────────────────────────────────────────
  const [showOfferModal, setShowOfferModal] = useState(false);
  const [offerChip, setOfferChip]           = useState<number | null>(null);
  const [offerCustomPrix, setOfferCustomPrix] = useState("");
  const [offerMessage, setOfferMessage]     = useState("");
  const [offerLoading, setOfferLoading]     = useState(false);
  const [offerError, setOfferError]         = useState<string | null>(null);
  const [offerBlockReason, setOfferBlockReason] = useState<string | null>(null);
  const [checkingOffer, setCheckingOffer]   = useState(false);

  // ── Counter modal (Contre-proposer) ──────────────────────────────────────
  const [showCounterModal, setShowCounterModal] = useState(false);
  const [counterNegId, setCounterNegId]         = useState<number | null>(null);
  const [counterFloor, setCounterFloor]         = useState(0);
  const [counterChip, setCounterChip]           = useState<number | null>(null);
  const [counterCustomPrix, setCounterCustomPrix] = useState("");
  const [counterMessage, setCounterMessage]     = useState("");
  const [counterLoading, setCounterLoading]     = useState(false);
  const [counterError, setCounterError]         = useState<string | null>(null);

  const [unreadMap, setUnreadMap] = useState<Map<string, number>>(new Map());

  // Map locale pour mettre à jour les aperçus de conversation (lastMessage + timestamp) sans rechargement serveur
  const [convPreviewMap, setConvPreviewMap] = useState<
    Map<string, { lastMessage: string; timestamp: string; sortDate: number }>
  >(new Map());

  const selectedConv = conversations.find((c) => c.id === selectedConvId);

  // Enrichir les conversations avec les données dynamiques + re-tri par activité récente
  const enrichedConversations = conversations
    .map((c) => {
      const preview = convPreviewMap.get(c.id);
      return {
        ...c,
        unreadCount: unreadMap.get(c.id) ?? 0,
        lastMessage: preview?.lastMessage ?? c.lastMessage,
        timestamp: preview?.timestamp ?? c.timestamp,
        _sortDate: preview?.sortDate ?? 0,
      };
    })
    .sort((a, b) => {
      if (b._sortDate !== a._sortDate) return b._sortDate - a._sortDate;
      return 0; // garder l'ordre serveur si pas de preview local
    })
    .map(({ _sortDate: _, ...c }) => c);

  const totalUnread = Array.from(unreadMap.values()).reduce((s, n) => s + n, 0);

  // Helper : mettre à jour l'aperçu d'une conversation
  const updateConvPreview = useCallback((convId: string, content: string, isoDate: string) => {
    setConvPreviewMap((prev) => {
      const next = new Map(prev);
      next.set(convId, {
        lastMessage: content,
        timestamp: formatMsgTime(isoDate),
        sortDate: new Date(isoDate).getTime(),
      });
      return next;
    });
  }, []);

  // ── Prix négocié pour la conversation sélectionnée ───────────────────────
  const [convPrixNegocie, setConvPrixNegocie] = useState<number | null>(null);

  useEffect(() => {
    if (!selectedConv || selectedConv.type !== "achat") {
      setConvPrixNegocie(null);
      return;
    }
    supabase
      .from("negociations")
      .select("prix_propose")
      .eq("annonce_id", Number(selectedConv.listing.id))
      .eq("acheteur_id", currentUserId)
      .eq("statut", "acceptee")
      .order("date_proposition", { ascending: false })
      .limit(1)
      .maybeSingle()
      .then(({ data }) => setConvPrixNegocie(data?.prix_propose ?? null));
  }, [selectedConvId, currentUserId]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Fetch unread counts for all conversations ─────────────────────────────
  const fetchUnreadCounts = useCallback(async () => {
    if (conversations.length === 0) return;
    const convIds = conversations.map((c) => Number(c.id));
    const { data } = await supabase
      .from("messages")
      .select("conversation_id")
      .in("conversation_id", convIds)
      .neq("sender_id", currentUserId)
      .eq("lu", false);
    const map = new Map<string, number>();
    (data ?? []).forEach((m) => {
      const id = String(m.conversation_id);
      map.set(id, (map.get(id) ?? 0) + 1);
    });
    setUnreadMap(map);
  }, [conversations, currentUserId]);

  // Fetch initial unread counts
  useEffect(() => { fetchUnreadCounts(); }, [fetchUnreadCounts]);

  // Dispatcher CustomEvent quand le total change → navbars mettent à jour
  useEffect(() => {
    window.dispatchEvent(new CustomEvent("unread-count-changed", { detail: totalUnread }));
  }, [totalUnread]);

  // ── Fetch messages ────────────────────────────────────────────────────────
  const fetchMessages = useCallback(
    async (convId: string) => {
      setLoadingMsgs(true);
      try {
        const { data, error } = await supabase
          .from("messages")
          .select("id, sender_id, contenu, date_envoi, lu, type, negociation_id")
          .eq("conversation_id", Number(convId))
          .order("date_envoi", { ascending: true });

        if (error) {
          console.error("[fetchMessages]", error.message);
          setMessages([]);
          return;
        }

        const conv = conversations.find((c) => c.id === convId);

        // Fetch negociation data for negociation-type messages
        const negIds = (data ?? [])
          .filter((m: DBMessage) => m.type === "negociation" && m.negociation_id)
          .map((m: DBMessage) => m.negociation_id as number);

        let negMap: Record<number, DBNeg> = {};
        if (negIds.length > 0) {
          const { data: negs } = await supabase
            .from("negociations")
            .select("id, prix_propose, statut")
            .in("id", negIds);
          for (const n of negs ?? []) {
            negMap[n.id] = n as DBNeg;
          }
        }

        setMessages(
          (data ?? []).map((m: DBMessage) => ({
            id: String(m.id),
            senderId: m.sender_id,
            senderName: m.sender_id === currentUserId ? "Moi" : conv?.user.name ?? "",
            senderAvatar: m.sender_id === currentUserId ? undefined : conv?.user.avatar,
            content: m.contenu,
            timestamp: formatMsgTime(m.date_envoi),
            isSelf: m.sender_id === currentUserId,
            lu: m.lu,
            type: m.type === "negociation" ? "negociation" : "text",
            negociationId: m.negociation_id ?? undefined,
            negociationData:
              m.negociation_id && negMap[m.negociation_id]
                ? {
                    id: m.negociation_id,
                    prixPropose: negMap[m.negociation_id].prix_propose,
                    statut: negMap[m.negociation_id].statut,
                  }
                : undefined,
          }))
        );
      } finally {
        setLoadingMsgs(false);
      }
    },
    [currentUserId, conversations]
  );

  // ── Mark messages as read ─────────────────────────────────────────────────
  const markAsRead = useCallback(async (convId: string) => {
    await supabase
      .from("messages")
      .update({ lu: true })
      .eq("conversation_id", Number(convId))
      .neq("sender_id", currentUserId)
      .eq("lu", false);
    // Mise à jour locale immédiate — pas besoin d'attendre le refetch
    setUnreadMap((prev) => {
      const next = new Map(prev);
      next.set(convId, 0);
      return next;
    });
  }, [currentUserId]);

  // ── Load on conversation change ───────────────────────────────────────────
  useEffect(() => {
    if (!selectedConvId) return;
    fetchMessages(selectedConvId);
    markAsRead(selectedConvId);
  }, [selectedConvId, fetchMessages, markAsRead]);

  // ── Realtime: new messages ────────────────────────────────────────────────
  useEffect(() => {
    if (!selectedConvId) return;

    const channel = supabase
      .channel(`conv-${selectedConvId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `conversation_id=eq.${selectedConvId}`,
        },
        (payload) => {
          const newMsg = payload.new as DBMessage;

          // Messages de négociation : refetch pour récupérer les données négociation
          if (newMsg.type === "negociation") {
            fetchMessages(selectedConvId);
            markAsRead(selectedConvId);
            return;
          }

          const isSelf = newMsg.sender_id === currentUserId;
          const conv = conversations.find((c) => c.id === selectedConvId);

          setMessages((prev) => {
            if (isSelf) {
              // Remplacer le message temporaire (optimistic) par le vrai ID DB
              const tempItem = [...prev].reverse().find((m) => m.id.startsWith("temp-"));
              if (tempItem) {
                return prev.map((m) =>
                  m.id === tempItem.id ? { ...m, id: String(newMsg.id), lu: newMsg.lu } : m
                );
              }
              return prev;
            }
            // Message reçu — éviter les doublons
            if (prev.some((m) => m.id === String(newMsg.id))) return prev;
            return [
              ...prev,
              {
                id: String(newMsg.id),
                senderId: newMsg.sender_id,
                senderName: conv?.user.name ?? "",
                senderAvatar: conv?.user.avatar,
                content: newMsg.contenu,
                timestamp: formatMsgTime(newMsg.date_envoi),
                isSelf: false,
                lu: newMsg.lu,
                type: "text" as const,
              },
            ];
          });

          if (!isSelf) markAsRead(selectedConvId);
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [selectedConvId, fetchMessages, markAsRead, currentUserId, conversations]);

  // ── Realtime: nouveaux messages dans convs non-ouvertes → incrémenter badge ─
  useEffect(() => {
    if (conversations.length === 0) return;
    const convIds = conversations.map((c) => Number(c.id));

    const channel = supabase
      .channel("all-convs-inserts")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "messages" },
        (payload) => {
          const msg = payload.new as {
            id: number; conversation_id: number; sender_id: string;
            contenu: string; date_envoi: string;
          };
          if (!convIds.includes(msg.conversation_id)) return;

          const convId = String(msg.conversation_id);

          // Mettre à jour le preview sidebar pour TOUTES les convs
          updateConvPreview(convId, msg.contenu, msg.date_envoi);

          // Incrémenter badge uniquement pour les convs non-ouvertes avec msg reçu
          if (msg.sender_id !== currentUserId && convId !== selectedConvId) {
            setUnreadMap((prev) => {
              const next = new Map(prev);
              next.set(convId, (next.get(convId) ?? 0) + 1);
              return next;
            });
          }
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [conversations, currentUserId, selectedConvId, updateConvPreview]);

  // ── Realtime: message lu updates (ticks deviennent orange côté expéditeur) ─
  useEffect(() => {
    if (!selectedConvId) return;

    const channel = supabase
      .channel(`msg-lu-${selectedConvId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "messages",
          filter: `conversation_id=eq.${selectedConvId}`,
        },
        (payload) => {
          const updated = payload.new as { id: number; lu: boolean };
          setMessages((prev) =>
            prev.map((m) =>
              m.id === String(updated.id) ? { ...m, lu: updated.lu } : m
            )
          );
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [selectedConvId]);

  // ── Realtime: negociation status updates ─────────────────────────────────
  useEffect(() => {
    if (!selectedConvId) return;

    const channel = supabase
      .channel(`neg-updates-${selectedConvId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "negociations",
        },
        (payload) => {
          const updated = payload.new as DBNeg;
          setMessages((prev) =>
            prev.map((m) =>
              m.negociationId === updated.id
                ? {
                    ...m,
                    negociationData: m.negociationData
                      ? { ...m.negociationData, statut: updated.statut }
                      : m.negociationData,
                  }
                : m
            )
          );
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [selectedConvId]);

  // ── Scroll to bottom ──────────────────────────────────────────────────────
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // ── Select conversation ───────────────────────────────────────────────────
  const handleSelect = (id: string) => {
    setSelectedConvId(id);
    setMobileView("chat");
    router.replace(`/messages?conv=${id}`, { scroll: false });
  };

  const closeConversation = () => {
    setSelectedConvId(null);
    setMobileView("list");
    setCtxMenu(null);
    router.replace("/messages", { scroll: false });
  };

  // Fermer le context menu sur clic ou touche Escape
  useEffect(() => {
    if (!ctxMenu) return;
    const close = () => setCtxMenu(null);
    document.addEventListener("click", close);
    document.addEventListener("contextmenu", close);
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") close(); });
    return () => {
      document.removeEventListener("click", close);
      document.removeEventListener("contextmenu", close);
    };
  }, [ctxMenu]);

  // ── Send plain message ────────────────────────────────────────────────────
  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    const content = inputMessage.trim();
    if (!content || !selectedConvId || sending) return;

    setInputMessage("");
    setSending(true);

    const tempId = `temp-${Date.now()}`;
    const nowIso = new Date().toISOString();
    setMessages((prev) => [
      ...prev,
      {
        id: tempId,
        senderId: currentUserId,
        senderName: "Moi",
        content,
        timestamp: new Date().toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" }),
        isSelf: true,
        type: "text",
      },
    ]);
    // Mettre à jour le preview sidebar immédiatement (optimistic)
    updateConvPreview(selectedConvId, content, nowIso);

    const { error } = await supabase.from("messages").insert({
      conversation_id: Number(selectedConvId),
      sender_id: currentUserId,
      contenu: content,
    });

    if (error) {
      setMessages((prev) => prev.filter((m) => m.id !== tempId));
      setInputMessage(content);
    }
    setSending(false);
  };

  // ── Accept negociation ────────────────────────────────────────────────────
  const handleAcceptNeg = async (negId: number) => {
    await supabase.from("negociations").update({ statut: "acceptee" }).eq("id", negId);
    setMessages((prev) =>
      prev.map((m) =>
        m.negociationId === negId && m.negociationData
          ? { ...m, negociationData: { ...m.negociationData, statut: "acceptee" } }
          : m
      )
    );
  };

  // ── Refuse negociation ────────────────────────────────────────────────────
  const handleRefuseNeg = async (negId: number) => {
    await supabase.from("negociations").update({ statut: "refusee" }).eq("id", negId);
    setMessages((prev) =>
      prev.map((m) =>
        m.negociationId === negId && m.negociationData
          ? { ...m, negociationData: { ...m.negociationData, statut: "refusee" } }
          : m
      )
    );
  };

  // ── Open offer modal (avec vérification unicité) ─────────────────────────
  const openOfferModal = async () => {
    if (!selectedConv) return;
    setOfferBlockReason(null);
    setCheckingOffer(true);

    const { data: existing } = await supabase
      .from("negociations")
      .select("id, statut")
      .eq("annonce_id", Number(selectedConv.listing.id))
      .eq("acheteur_id", currentUserId)
      .in("statut", ["en_attente", "acceptee"])
      .maybeSingle();

    setCheckingOffer(false);

    if (existing) {
      setOfferBlockReason(
        existing.statut === "acceptee"
          ? "Vous avez déjà un accord de prix sur cet article."
          : "Vous avez déjà une négociation en cours. Attendez la réponse du vendeur."
      );
      return;
    }

    setOfferChip(null);
    setOfferCustomPrix("");
    setOfferMessage("");
    setOfferError(null);
    setShowOfferModal(true);
  };

  // ── Open counter modal ────────────────────────────────────────────────────
  const handleOpenCounter = (negId: number, prixPropose: number) => {
    setCounterNegId(negId);
    setCounterFloor(prixPropose);
    setCounterChip(null);
    setCounterCustomPrix("");
    setCounterMessage("");
    setCounterError(null);
    setShowCounterModal(true);
  };

  // ── Send offer (Faire une offre) ──────────────────────────────────────────
  const handleSendOffer = async () => {
    if (!selectedConv || !selectedConvId) return;
    const listingPrice = selectedConv.listing.price;
    const prix =
      offerChip !== null ? offerChip : Number(offerCustomPrix.replace(/\s/g, ""));

    if (!prix || prix <= 0 || prix >= listingPrice) {
      setOfferError("Le prix doit être inférieur au prix affiché.");
      return;
    }

    setOfferLoading(true);
    setOfferError(null);

    try {
      const vendeurId =
        selectedConv.type === "achat" ? selectedConv.user.id : currentUserId;

      const { data: neg, error: negErr } = await supabase
        .from("negociations")
        .insert({
          annonce_id: Number(selectedConv.listing.id),
          acheteur_id: currentUserId,
          vendeur_id: vendeurId,
          prix_propose: prix,
          conversation_id: Number(selectedConvId),
          message: offerMessage.trim() || null,
          statut: "en_attente",
        })
        .select("id")
        .maybeSingle();

      if (negErr || !neg) throw new Error("Impossible d'envoyer l'offre.");

      await supabase.from("messages").insert({
        conversation_id: Number(selectedConvId),
        sender_id: currentUserId,
        contenu: `Proposition de prix : ${prix.toLocaleString("fr-FR")} FCFA`,
        type: "negociation",
        negociation_id: neg.id,
      });

      setShowOfferModal(false);
      setOfferChip(null);
      setOfferCustomPrix("");
      setOfferMessage("");
      fetchMessages(selectedConvId);
    } catch (e: unknown) {
      setOfferError(e instanceof Error ? e.message : "Une erreur est survenue.");
      setOfferLoading(false);
    }
  };

  // ── Send counter-offer ────────────────────────────────────────────────────
  const handleSendCounter = async () => {
    if (!counterNegId || !selectedConv || !selectedConvId) return;
    const prix =
      counterChip !== null ? counterChip : Number(counterCustomPrix.replace(/\s/g, ""));

    if (!prix || prix <= counterFloor) {
      setCounterError("Le prix doit être supérieur à l'offre initiale.");
      return;
    }
    if (prix >= selectedConv.listing.price) {
      setCounterError("Le prix doit rester inférieur au prix affiché.");
      return;
    }

    setCounterLoading(true);
    setCounterError(null);

    try {
      // Cancel current negociation
      await supabase
        .from("negociations")
        .update({ statut: "annulee" })
        .eq("id", counterNegId);

      const acheteurId =
        selectedConv.type === "vente" ? selectedConv.user.id : currentUserId;
      const vendeurId =
        selectedConv.type === "vente" ? currentUserId : selectedConv.user.id;

      const { data: newNeg, error: negErr } = await supabase
        .from("negociations")
        .insert({
          annonce_id: Number(selectedConv.listing.id),
          acheteur_id: acheteurId,
          vendeur_id: vendeurId,
          prix_propose: prix,
          conversation_id: Number(selectedConvId),
          message: counterMessage.trim() || null,
          statut: "en_attente",
        })
        .select("id")
        .maybeSingle();

      if (negErr || !newNeg) throw new Error("Impossible d'envoyer la contre-offre.");

      await supabase.from("messages").insert({
        conversation_id: Number(selectedConvId),
        sender_id: currentUserId,
        contenu: `Contre-proposition : ${prix.toLocaleString("fr-FR")} FCFA`,
        type: "negociation",
        negociation_id: newNeg.id,
      });

      setShowCounterModal(false);
      setCounterChip(null);
      setCounterCustomPrix("");
      setCounterMessage("");
      fetchMessages(selectedConvId);
    } catch (e: unknown) {
      setCounterError(e instanceof Error ? e.message : "Une erreur est survenue.");
      setCounterLoading(false);
    }
  };

  // ── Offer modal chips ─────────────────────────────────────────────────────
  const offerOriginalPrice = selectedConv?.listing.price ?? 0;
  const offerChips = offerOriginalPrice > 0
    ? [
        { label: "-5%",  value: Math.round(offerOriginalPrice * 0.95) },
        { label: "-15%", value: Math.round(offerOriginalPrice * 0.85) },
        { label: "-25%", value: Math.round(offerOriginalPrice * 0.75) },
      ]
    : [];
  const offerPrixEffectif =
    offerChip !== null ? offerChip
    : offerCustomPrix ? Number(offerCustomPrix.replace(/\s/g, ""))
    : null;
  const offerEconomie =
    offerPrixEffectif !== null && offerPrixEffectif > 0 && offerPrixEffectif < offerOriginalPrice
      ? offerOriginalPrice - offerPrixEffectif
      : null;

  // ── Counter modal chips (+% above floor) ─────────────────────────────────
  const counterChips = counterFloor > 0
    ? [
        { label: "+5%",  value: Math.round(counterFloor * 1.05) },
        { label: "+10%", value: Math.round(counterFloor * 1.10) },
        { label: "+20%", value: Math.round(counterFloor * 1.20) },
      ]
    : [];
  const counterPrixEffectif =
    counterChip !== null ? counterChip
    : counterCustomPrix ? Number(counterCustomPrix.replace(/\s/g, ""))
    : null;

  // ── Empty state ───────────────────────────────────────────────────────────
  if (conversations.length === 0) {
    return (
      <div className="w-full max-w-[1280px] flex flex-col items-center justify-center bg-white rounded-2xl border border-[#E3E2E2] flex-1 min-h-0 shadow-[0_4px_20px_rgba(19,27,45,0.06)] gap-4 text-center px-6">
        <div className="flex h-20 w-20 items-center justify-center rounded-full bg-[#F4F3F3]">
          <MessageSquareDashed className="h-9 w-9 text-[#E3E2E2]" strokeWidth={1} />
        </div>
        <h2 className="text-xl font-bold text-[#131B2D]">Aucune conversation</h2>
        <p className="max-w-xs text-sm text-[#565E73]">
          Contactez un vendeur depuis une annonce pour démarrer un échange.
        </p>
      </div>
    );
  }

  // ── Main render ───────────────────────────────────────────────────────────
  return (
    <>
      <div className="w-full max-w-[1280px] bg-white rounded-2xl border border-[#E3E2E2] overflow-hidden shadow-[0_4px_20px_rgba(19,27,45,0.06)] flex flex-col lg:flex-row flex-1 min-h-0">
        {/* Sidebar — full screen on mobile when mobileView==="list"; fixed width on desktop */}
        <ChatSidebar
          conversations={enrichedConversations}
          selectedId={selectedConvId ?? ""}
          onSelect={handleSelect}
          activeFilter={filter}
          onFilterChange={setFilter}
          searchQuery={search}
          onSearchChange={setSearch}
          totalUnread={totalUnread}
          className={`${mobileView === "list" ? "flex" : "hidden"} lg:flex`}
        />

        {/* Zone messages */}
        {selectedConv ? (
          <section
            className={`${mobileView === "chat" ? "flex" : "hidden"} lg:flex flex-col flex-1 min-w-0 min-h-0 overflow-hidden bg-[#FAF9F9]`}
            onContextMenu={(e) => {
              e.preventDefault();
              setCtxMenu({ x: e.clientX, y: e.clientY });
            }}
          >
            {/* Header contact */}
            <div className="h-16 px-4 sm:px-6 bg-white border-b border-[#E3E2E2] flex items-center justify-between shrink-0">
              <div className="flex items-center gap-2 sm:gap-3 min-w-0">
                {/* Back button — mobile only */}
                <button
                  type="button"
                  onClick={closeConversation}
                  className="lg:hidden flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-[#565E73] hover:bg-[#F4F3F3] transition-colors"
                  aria-label="Retour"
                >
                  <ArrowLeft className="h-4 w-4" />
                </button>
                <div className="relative h-10 w-10 shrink-0">
                  {selectedConv.user.avatar ? (
                    <Image
                      src={selectedConv.user.avatar}
                      alt={selectedConv.user.name}
                      fill
                      className="object-cover rounded-full"
                    />
                  ) : (
                    <div className="h-10 w-10 rounded-full bg-[#E8F1F5] flex items-center justify-center text-sm font-bold text-[#131B2D]">
                      {selectedConv.user.initials}
                    </div>
                  )}
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-1.5">
                    <h2 className="text-sm font-bold text-[#1A1C1C] truncate">
                      {selectedConv.user.name}
                    </h2>
                    {selectedConv.user.verified && (
                      <CheckCircle2 className="h-3.5 w-3.5 fill-[#00966B] text-white shrink-0" />
                    )}
                  </div>
                  <p className="text-[11px] text-[#565E73] font-semibold truncate">
                    {selectedConv.user.statusText}
                  </p>
                </div>
              </div>

              <button
                type="button"
                aria-label="Plus d'options"
                className="flex h-9 w-9 items-center justify-center rounded-full hover:bg-[#F4F3F3] text-[#565E73] hover:text-[#131B2D] transition-colors"
              >
                <MoreVertical className="h-4 w-4" />
              </button>
            </div>

            {/* Bannière annonce */}
            <ChatListingBanner
              listing={selectedConv.listing}
              prixNegocie={convPrixNegocie}
              onMakeOfferClick={selectedConv.type === "achat" ? openOfferModal : undefined}
            />
            {offerBlockReason && (
              <div className="mx-4 mt-2 rounded-xl bg-[#FFF7F4] border border-[#FC7138]/30 px-4 py-2.5 text-xs font-semibold text-[#FC7138]">
                {offerBlockReason}
              </div>
            )}

            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
              {loadingMsgs ? (
                <div className="flex justify-center items-center h-full">
                  <Loader2 className="h-6 w-6 animate-spin text-[#FC7138]" />
                </div>
              ) : messages.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full gap-2 text-center">
                  <p className="text-sm font-semibold text-[#131B2D]">Commencez la conversation</p>
                  <p className="text-xs text-[#565E73]">
                    Posez vos questions sur{" "}
                    <span className="font-semibold">{selectedConv.listing.title}</span>
                  </p>
                </div>
              ) : (
                messages.map((msg) => {
                  // ── Negociation card ──────────────────────────────────
                  if (msg.type === "negociation" && msg.negociationData) {
                    return (
                      <div
                        key={msg.id}
                        className={`flex ${msg.isSelf ? "justify-end" : "items-end gap-2.5"}`}
                      >
                        {!msg.isSelf && (
                          msg.senderAvatar ? (
                            <div className="relative h-8 w-8 shrink-0 mb-4">
                              <Image src={msg.senderAvatar} alt={msg.senderName} fill className="rounded-full object-cover" />
                            </div>
                          ) : (
                            <div className="h-8 w-8 rounded-full bg-[#E8F1F5] shrink-0 mb-4 flex items-center justify-center text-xs font-bold text-[#131B2D]">
                              {msg.senderName.slice(0, 2).toUpperCase()}
                            </div>
                          )
                        )}
                        <NegCard
                          msg={msg}
                          isAcheteur={selectedConv.type === "achat"}
                          originalPrice={selectedConv.listing.price}
                          onAccept={handleAcceptNeg}
                          onCounter={handleOpenCounter}
                          onRefuse={handleRefuseNeg}
                          onAcheter={
                            selectedConv.type === "achat" &&
                            msg.negociationData?.statut === "acceptee"
                              ? () =>
                                  router.push(
                                    `/paiement?annonce=${selectedConv.listing.id}&vendeur=${selectedConv.user.id}&montant=${msg.negociationData!.prixPropose}`
                                  )
                              : undefined
                          }
                        />
                      </div>
                    );
                  }

                  // ── Normal message ────────────────────────────────────
                  if (msg.isSelf) {
                    return (
                      <div key={msg.id} className="flex flex-col items-end">
                        <div className="max-w-[78%] rounded-2xl rounded-tr-sm bg-[#FC7138] p-4 text-xs md:text-sm text-white shadow-[0_4px_16px_rgba(252,113,56,0.18)] leading-relaxed">
                          {msg.content}
                        </div>
                        <div className="mt-1 flex items-center gap-1 mr-1">
                          <span className="text-[10px] text-[#76777D] font-medium">
                            {msg.timestamp}
                          </span>
                          <CheckCheck
                            className={`h-3.5 w-3.5 shrink-0 transition-colors ${
                              msg.lu ? "text-[#FC7138]" : "text-[#B0B0B0]"
                            }`}
                          />
                        </div>
                      </div>
                    );
                  }

                  return (
                    <div key={msg.id} className="flex items-end gap-2.5 max-w-[80%]">
                      {msg.senderAvatar ? (
                        <div className="relative h-8 w-8 shrink-0 mb-5">
                          <Image src={msg.senderAvatar} alt={msg.senderName} fill className="rounded-full object-cover" />
                        </div>
                      ) : (
                        <div className="h-8 w-8 rounded-full bg-[#E8F1F5] shrink-0 mb-5 flex items-center justify-center text-xs font-bold text-[#131B2D]">
                          {msg.senderName.slice(0, 2).toUpperCase()}
                        </div>
                      )}
                      <div className="flex flex-col items-start">
                        <div className="rounded-2xl rounded-tl-sm bg-white border border-[#E3E2E2]/60 p-4 text-xs md:text-sm text-[#1A1C1C] shadow-sm leading-relaxed">
                          {msg.content}
                        </div>
                        <span className="text-[10px] text-[#76777D] font-medium mt-1 ml-1">
                          {msg.timestamp}
                        </span>
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Saisie */}
            <div className="p-4 bg-white border-t border-[#E3E2E2] shrink-0">
              <form onSubmit={handleSend} className="flex items-center gap-2">
                <input
                  type="text"
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  placeholder={`Message à ${selectedConv.user.name}...`}
                  className="h-11 flex-1 rounded-full bg-[#F4F3F3] px-4 text-base md:text-sm text-[#1A1C1C] placeholder-[#76777D] outline-none focus:ring-2 focus:ring-[#FC7138]/20 transition-all"
                />
                <button
                  type="submit"
                  aria-label="Envoyer"
                  disabled={!inputMessage.trim() || sending}
                  className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-[#FC7138] text-white shadow-[0_4px_16px_rgba(252,113,56,0.3)] hover:bg-[#e05f29] transition-all active:scale-95 disabled:opacity-50"
                >
                  {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : <SendHorizontal className="h-4 w-4" />}
                </button>
              </form>
            </div>
          </section>
        ) : (
          /* Placeholder — aucune conversation sélectionnée (desktop only) */
          <div className="hidden lg:flex flex-1 relative flex-col items-center justify-center text-center gap-4 p-8 bg-[#FAF9F9] overflow-hidden">
            {/* Motif de fond */}
            <svg
              className="pointer-events-none absolute inset-0 h-full w-full opacity-[0.035]"
              xmlns="http://www.w3.org/2000/svg"
            >
              <defs>
                <pattern id="msg-grid" width="40" height="40" patternUnits="userSpaceOnUse">
                  <circle cx="20" cy="20" r="1.5" fill="#131B2D" />
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#msg-grid)" />
            </svg>

            {/* Icône centrale */}
            <div className="relative flex h-20 w-20 items-center justify-center rounded-2xl bg-white shadow-[0_4px_24px_rgba(19,27,45,0.08)]">
              <MessageSquareDashed className="h-9 w-9 text-[#E3E2E2]" strokeWidth={1.5} />
              <span className="absolute -top-1.5 -right-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-[#FC7138] text-[9px] font-black text-white">
                {totalUnread > 0 ? totalUnread : ""}
              </span>
            </div>

            <div className="relative space-y-1">
              <p className="text-base font-extrabold text-[#131B2D]">Vos conversations</p>
              <p className="text-xs text-[#76777D] max-w-[220px]">
                Sélectionnez une conversation à gauche pour afficher les messages.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* ── Context menu (clic droit dans le chat) ───────────────────────────── */}
      {ctxMenu && (
        <div
          className="fixed z-[60] min-w-[200px] rounded-xl bg-white shadow-[0_8px_30px_rgba(19,27,45,0.15)] border border-[#E3E2E2]/60 py-1.5 overflow-hidden"
          style={{
            top: Math.min(ctxMenu.y, window.innerHeight - 60),
            left: Math.min(ctxMenu.x, window.innerWidth - 210),
          }}
          onClick={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            onClick={closeConversation}
            className="flex w-full items-center gap-3 px-4 py-2.5 text-sm text-[#1A1C1C] hover:bg-[#FFF7F4] hover:text-[#FC7138] transition-colors"
          >
            <PanelLeftClose className="h-4 w-4 shrink-0" />
            Fermer la conversation
          </button>
        </div>
      )}

      {/* ── Modale Faire une offre ────────────────────────────────────────────── */}
      {showOfferModal && selectedConv && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setShowOfferModal(false)} />
          <div className="relative z-10 w-full max-w-md max-h-[90vh] overflow-y-auto rounded-2xl bg-white shadow-2xl">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-[#F4F3F3] px-6 py-4">
              <div>
                <h2 className="text-base font-bold text-[#131B2D]">Faire une offre</h2>
                <p className="mt-0.5 text-xs text-[#565E73] line-clamp-1">{selectedConv.listing.title}</p>
              </div>
              <button type="button" onClick={() => setShowOfferModal(false)} className="rounded-full p-1.5 hover:bg-[#F4F3F3]">
                <X className="h-4 w-4 text-[#565E73]" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-5">
              {/* Prix actuel */}
              <div className="rounded-xl bg-[#F4F3F3] px-4 py-3 text-center">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-[#565E73]">Prix affiché</p>
                <p className="mt-0.5 text-xl font-extrabold text-[#131B2D]">
                  {offerOriginalPrice.toLocaleString("fr-FR")} FCFA
                </p>
              </div>

              {/* Chips */}
              <div>
                <p className="mb-2 text-xs font-bold text-[#131B2D]">Réduction rapide</p>
                <div className="flex gap-2">
                  {offerChips.map((c) => (
                    <button
                      key={c.label}
                      type="button"
                      onClick={() => { setOfferChip(c.value); setOfferCustomPrix(""); }}
                      className={`flex-1 rounded-full border px-3 py-2 text-xs font-bold transition-all ${
                        offerChip === c.value
                          ? "border-[#131B2D] bg-[#131B2D] text-white"
                          : "border-[#E3E2E2] bg-white text-[#131B2D] hover:border-[#131B2D]"
                      }`}
                    >
                      <span className="block">{c.label}</span>
                      <span className={`block text-[10px] font-normal mt-0.5 ${offerChip === c.value ? "text-white/70" : "text-[#565E73]"}`}>
                        {c.value.toLocaleString("fr-FR")}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Prix libre */}
              <div>
                <label className="text-xs font-bold text-[#131B2D]" htmlFor="offer-prix">
                  Ou saisir un prix manuellement (FCFA)
                </label>
                <input
                  id="offer-prix"
                  type="number"
                  min={1}
                  value={offerCustomPrix}
                  onChange={(e) => { setOfferCustomPrix(e.target.value); setOfferChip(null); }}
                  placeholder={`Ex : ${Math.round(offerOriginalPrice * 0.9).toLocaleString("fr-FR")}`}
                  className="mt-1.5 h-11 w-full rounded-xl border border-[#E3E2E2] bg-white px-4 text-base md:text-sm text-[#131B2D] placeholder:text-[#C4C4C4] focus:border-[#131B2D] focus:outline-none"
                />
              </div>

              {/* Indicateur */}
              {offerEconomie !== null && (
                <div className="flex items-center gap-2 rounded-xl bg-[#E8F5EE] px-4 py-2.5">
                  <TrendingDown className="h-4 w-4 shrink-0 text-[#00966B]" />
                  <p className="text-xs font-semibold text-[#00966B]">
                    Vous économisez{" "}
                    <span className="font-extrabold">{offerEconomie.toLocaleString("fr-FR")} FCFA</span>{" "}
                    ({Math.round((offerEconomie / offerOriginalPrice) * 100)}%)
                  </p>
                </div>
              )}

              {/* Message */}
              <div>
                <label className="text-xs font-bold text-[#131B2D]" htmlFor="offer-msg">
                  Message <span className="font-normal text-[#76777D]">(optionnel)</span>
                </label>
                <textarea
                  id="offer-msg"
                  rows={2}
                  value={offerMessage}
                  onChange={(e) => setOfferMessage(e.target.value)}
                  placeholder="Ex : Disponible ce week-end…"
                  className="mt-1.5 w-full resize-none rounded-xl border border-[#E3E2E2] bg-white px-4 py-2.5 text-base md:text-sm placeholder:text-[#C4C4C4] focus:border-[#131B2D] focus:outline-none"
                />
              </div>

              {offerError && (
                <p className="rounded-xl bg-red-50 px-4 py-2.5 text-xs font-semibold text-[#BA1A1A]">{offerError}</p>
              )}

              <div className="flex gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setShowOfferModal(false)}
                  disabled={offerLoading}
                  className="flex h-11 flex-1 items-center justify-center rounded-full border border-[#E3E2E2] text-sm font-semibold text-[#565E73] hover:bg-[#F4F3F3] transition-all disabled:opacity-50"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={handleSendOffer}
                  disabled={offerLoading || !offerPrixEffectif || offerPrixEffectif <= 0 || offerPrixEffectif >= offerOriginalPrice}
                  className="flex h-11 flex-1 items-center justify-center gap-2 rounded-full bg-[#131B2D] text-sm font-bold text-white hover:bg-[#1e2d4a] active:scale-[0.99] disabled:opacity-50"
                >
                  {offerLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <TrendingDown className="h-4 w-4" />}
                  {offerLoading ? "Envoi…" : "Envoyer l'offre"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Modale Contre-proposer ────────────────────────────────────────────── */}
      {showCounterModal && selectedConv && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setShowCounterModal(false)} />
          <div className="relative z-10 w-full max-w-md max-h-[90vh] overflow-y-auto rounded-2xl bg-white shadow-2xl">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-[#F4F3F3] px-6 py-4">
              <div>
                <h2 className="text-base font-bold text-[#131B2D]">Contre-proposer</h2>
                <p className="mt-0.5 text-xs text-[#565E73]">
                  Offre reçue : <span className="font-bold text-[#FC7138]">{counterFloor.toLocaleString("fr-FR")} FCFA</span>
                </p>
              </div>
              <button type="button" onClick={() => setShowCounterModal(false)} className="rounded-full p-1.5 hover:bg-[#F4F3F3]">
                <X className="h-4 w-4 text-[#565E73]" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-5">
              {/* Chips +% */}
              <div>
                <p className="mb-1.5 text-xs font-bold text-[#131B2D]">
                  Proposer un prix au-dessus de l&apos;offre
                </p>
                <p className="mb-3 text-[11px] text-[#76777D]">
                  Prix affiché : {selectedConv.listing.price.toLocaleString("fr-FR")} FCFA
                </p>
                <div className="flex gap-2">
                  {counterChips.map((c) => (
                    <button
                      key={c.label}
                      type="button"
                      onClick={() => { setCounterChip(c.value); setCounterCustomPrix(""); }}
                      className={`flex-1 rounded-full border px-3 py-2 text-xs font-bold transition-all ${
                        counterChip === c.value
                          ? "border-[#FC7138] bg-[#FC7138] text-white"
                          : "border-[#E3E2E2] bg-white text-[#131B2D] hover:border-[#FC7138]"
                      }`}
                    >
                      <span className="block">{c.label}</span>
                      <span className={`block text-[10px] font-normal mt-0.5 ${counterChip === c.value ? "text-white/70" : "text-[#565E73]"}`}>
                        {c.value.toLocaleString("fr-FR")}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Prix libre */}
              <div>
                <label className="text-xs font-bold text-[#131B2D]" htmlFor="counter-prix">
                  Ou saisir un prix manuellement (FCFA)
                </label>
                <input
                  id="counter-prix"
                  type="number"
                  min={counterFloor + 1}
                  value={counterCustomPrix}
                  onChange={(e) => { setCounterCustomPrix(e.target.value); setCounterChip(null); }}
                  placeholder={`Ex : ${Math.round(counterFloor * 1.08).toLocaleString("fr-FR")}`}
                  className="mt-1.5 h-11 w-full rounded-xl border border-[#E3E2E2] bg-white px-4 text-base md:text-sm placeholder:text-[#C4C4C4] focus:border-[#FC7138] focus:outline-none"
                />
              </div>

              {/* Indicateur */}
              {counterPrixEffectif !== null && counterPrixEffectif > counterFloor && (
                <div className="flex items-center gap-2 rounded-xl bg-[#FFF7F4] border border-[#FC7138]/20 px-4 py-2.5">
                  <TrendingUp className="h-4 w-4 shrink-0 text-[#FC7138]" />
                  <p className="text-xs font-semibold text-[#FC7138]">
                    +{(counterPrixEffectif - counterFloor).toLocaleString("fr-FR")} FCFA par rapport à l&apos;offre (
                    +{Math.round(((counterPrixEffectif - counterFloor) / counterFloor) * 100)}%)
                  </p>
                </div>
              )}

              {/* Message */}
              <div>
                <label className="text-xs font-bold text-[#131B2D]" htmlFor="counter-msg">
                  Message <span className="font-normal text-[#76777D]">(optionnel)</span>
                </label>
                <textarea
                  id="counter-msg"
                  rows={2}
                  value={counterMessage}
                  onChange={(e) => setCounterMessage(e.target.value)}
                  placeholder="Ex : Je peux faire ce prix si vous passez demain…"
                  className="mt-1.5 w-full resize-none rounded-xl border border-[#E3E2E2] bg-white px-4 py-2.5 text-base md:text-sm placeholder:text-[#C4C4C4] focus:border-[#131B2D] focus:outline-none"
                />
              </div>

              {counterError && (
                <p className="rounded-xl bg-red-50 px-4 py-2.5 text-xs font-semibold text-[#BA1A1A]">{counterError}</p>
              )}

              <div className="flex gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setShowCounterModal(false)}
                  disabled={counterLoading}
                  className="flex h-11 flex-1 items-center justify-center rounded-full border border-[#E3E2E2] text-sm font-semibold text-[#565E73] hover:bg-[#F4F3F3] disabled:opacity-50"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={handleSendCounter}
                  disabled={
                    counterLoading ||
                    !counterPrixEffectif ||
                    counterPrixEffectif <= counterFloor ||
                    counterPrixEffectif >= (selectedConv?.listing.price ?? 0)
                  }
                  className="flex h-11 flex-1 items-center justify-center gap-2 rounded-full bg-[#FC7138] text-sm font-bold text-white hover:bg-[#e05f29] active:scale-[0.99] disabled:opacity-50"
                >
                  {counterLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Handshake className="h-4 w-4" />}
                  {counterLoading ? "Envoi…" : "Envoyer"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
