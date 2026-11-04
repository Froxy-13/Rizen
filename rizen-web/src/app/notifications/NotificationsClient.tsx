"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Bell, MessageSquare, Tag, ArrowLeft, CheckCheck, Loader2,
} from "lucide-react";
import { supabase } from "@/lib/supabase";

function timeAgoFr(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins  = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days  = Math.floor(diff / 86400000);
  if (mins < 1)   return "à l'instant";
  if (mins < 60)  return `il y a ${mins} min`;
  if (hours < 24) return `il y a ${hours} h`;
  if (days === 1) return "hier";
  if (days < 7)   return `il y a ${days} jours`;
  return new Date(dateStr).toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
}

interface Notification {
  id: number;
  utilisateur_id: string;
  titre: string;
  message: string;
  type: string;
  lu: boolean;
  lien: string | null;
  date_notification: string;
  created_at: string;
}

interface Props {
  userId: string;
  initialNotifications: Notification[];
}

function getTypeIcon(type: string) {
  if (type === "message") return <MessageSquare className="h-4 w-4 text-[#FC7138]" />;
  if (type === "negociation") return <Tag className="h-4 w-4 text-[#FC7138]" />;
  return <Bell className="h-4 w-4 text-[#FC7138]" />;
}

function groupByDate(notifs: Notification[]): Array<{ label: string; items: Notification[] }> {
  const now = new Date();
  const today    = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today.getTime() - 86400000);
  const weekAgo   = new Date(today.getTime() - 7 * 86400000);

  const groups: Record<string, Notification[]> = {
    "Aujourd'hui":    [],
    "Hier":           [],
    "Cette semaine":  [],
    "Plus ancien":    [],
  };

  for (const n of notifs) {
    const d = new Date(n.date_notification);
    const day = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    if (day >= today)     groups["Aujourd'hui"].push(n);
    else if (day >= yesterday) groups["Hier"].push(n);
    else if (day >= weekAgo)   groups["Cette semaine"].push(n);
    else                       groups["Plus ancien"].push(n);
  }

  return Object.entries(groups)
    .filter(([, items]) => items.length > 0)
    .map(([label, items]) => ({ label, items }));
}

export function NotificationsClient({ userId, initialNotifications }: Props) {
  const router = useRouter();
  const [notifications, setNotifications] = useState<Notification[]>(initialNotifications);
  const [markingAll, setMarkingAll] = useState(false);

  const unreadCount = notifications.filter((n) => !n.lu).length;

  // Dispatch badge update
  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent("notification-count-changed", { detail: unreadCount })
    );
  }, [unreadCount]);

  // Realtime subscription
  useEffect(() => {
    const channel = supabase
      .channel("notifs-realtime")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "notifications",
          filter: `utilisateur_id=eq.${userId}`,
        },
        (payload) => {
          setNotifications((prev) => [payload.new as Notification, ...prev]);
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [userId]);

  const markAsRead = useCallback(async (id: number) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, lu: true } : n))
    );
    await supabase
      .from("notifications")
      .update({ lu: true })
      .eq("id", id)
      .eq("utilisateur_id", userId);
  }, [userId]);

  const markAllAsRead = useCallback(async () => {
    if (unreadCount === 0) return;
    setMarkingAll(true);
    setNotifications((prev) => prev.map((n) => ({ ...n, lu: true })));
    await supabase
      .from("notifications")
      .update({ lu: true })
      .eq("utilisateur_id", userId)
      .eq("lu", false);
    setMarkingAll(false);
  }, [userId, unreadCount]);

  const handleNotifClick = useCallback(
    async (n: Notification) => {
      if (!n.lu) await markAsRead(n.id);
      if (n.lien) router.push(n.lien);
    },
    [markAsRead, router]
  );

  const groups = groupByDate(notifications);

  return (
    <main className="mx-auto max-w-2xl px-4 sm:px-6 py-8 pb-20 space-y-6">

      {/* En-tête */}
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={() => router.back()}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-white border border-[#E3E2E2] text-[#565E73] hover:bg-[#F4F3F3] transition-colors shadow-sm"
          >
            <ArrowLeft className="h-4 w-4" />
          </button>
          <div>
            <h1 className="text-xl font-extrabold text-[#131B2D]">Notifications</h1>
            {unreadCount > 0 && (
              <p className="text-xs text-[#76777D] mt-0.5">
                {unreadCount} non {unreadCount > 1 ? "lues" : "lue"}
              </p>
            )}
          </div>
        </div>

        {unreadCount > 0 && (
          <button
            type="button"
            onClick={markAllAsRead}
            disabled={markingAll}
            className="flex items-center gap-1.5 text-xs font-semibold text-[#FC7138] hover:underline disabled:opacity-50"
          >
            {markingAll ? (
              <Loader2 className="h-3.5 w-3.5 animate-spin" />
            ) : (
              <CheckCheck className="h-3.5 w-3.5" />
            )}
            Tout marquer comme lu
          </button>
        )}
      </div>

      {/* Liste vide */}
      {notifications.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-[#FFF0E8]">
            <Bell className="h-7 w-7 text-[#FC7138]" />
          </div>
          <div className="text-center">
            <p className="text-sm font-bold text-[#131B2D]">Aucune notification</p>
            <p className="mt-1 text-xs text-[#76777D]">Vous serez notifié de vos messages et offres.</p>
          </div>
        </div>
      )}

      {/* Groupes */}
      {groups.map(({ label, items }) => (
        <div key={label} className="space-y-2">
          <p className="text-xs font-bold uppercase tracking-wider text-[#76777D] px-1">{label}</p>
          <div className="space-y-2">
            {items.map((n) => (
              <NotifCard key={n.id} notif={n} onClick={() => handleNotifClick(n)} />
            ))}
          </div>
        </div>
      ))}
    </main>
  );
}

function NotifCard({ notif, onClick }: { notif: Notification; onClick: () => void }) {
  const timeAgo = timeAgoFr(notif.date_notification);

  const content = (
    <div
      role="button"
      tabIndex={0}
      onClick={onClick}
      onKeyDown={(e) => { if (e.key === "Enter") onClick(); }}
      className={`relative flex items-start gap-3 rounded-2xl border p-4 cursor-pointer transition-all hover:shadow-md active:scale-[0.99] ${
        notif.lu
          ? "bg-white border-[#E3E2E2]"
          : "bg-[#FFF7F4] border-[#FC7138]/20"
      }`}
    >
      {/* Icône */}
      <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full ${
        notif.lu ? "bg-[#F4F3F3]" : "bg-[#FFDBBF]"
      }`}>
        {getTypeIcon(notif.type)}
      </div>

      {/* Contenu */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between gap-2">
          <p className={`text-sm font-bold truncate ${notif.lu ? "text-[#131B2D]" : "text-[#FC7138]"}`}>
            {notif.titre}
          </p>
          <span className="text-[11px] text-[#76777D] shrink-0">{timeAgo}</span>
        </div>
        <p className="mt-0.5 text-xs text-[#565E73] line-clamp-2 leading-relaxed">
          {notif.message}
        </p>
      </div>

      {/* Point non lu */}
      {!notif.lu && (
        <span className="absolute top-4 right-4 h-2 w-2 rounded-full bg-[#FC7138]" />
      )}
    </div>
  );

  return notif.lien ? content : content;
}
