"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from "recharts";

// ─── Nav ─────────────────────────────────────────────────────────────
const NAV = [
  { icon: "dashboard",  label: "Vue d'ensemble", href: "/admin/dashboard", active: true },
  { icon: "storefront", label: "Annonces",        href: "/admin/annonces" },
  { icon: "group",      label: "Utilisateurs",    href: "/admin/utilisateurs" },
  { icon: "flag",       label: "Signalements",    href: "/admin/signalements" },
  { icon: "gavel",      label: "Litiges",         href: "/admin/litiges" },
  { icon: "category",   label: "Catégories",      href: "/admin/categories" },
  { icon: "bar_chart",  label: "Statistiques",    href: "/admin/statistiques" },
];

// ─── Helpers ──────────────────────────────────────────────────────────
function fmt(n: number) { return new Intl.NumberFormat("fr-FR").format(n); }

function timeAgo(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const m = Math.floor(diff / 60000);
  const h = Math.floor(diff / 3600000);
  const d = Math.floor(diff / 86400000);
  if (m < 2) return "À l'instant";
  if (m < 60) return `Il y a ${m}min`;
  if (h < 24) return `Il y a ${h}h`;
  if (d === 1) return "Hier";
  return `Il y a ${d}j`;
}

// ─── Périodes ─────────────────────────────────────────────────────────
const PERIODS = [
  { value: 7,   label: "7 derniers jours" },
  { value: 30,  label: "30 derniers jours" },
  { value: 90,  label: "3 derniers mois" },
  { value: 180, label: "6 derniers mois" },
  { value: 365, label: "Cette année" },
] as const;

type PeriodDays = typeof PERIODS[number]["value"];

// Génère un tableau de N jours (J-(N-1) → aujourd'hui)
function lastNDays(n: number): { key: string; label: string }[] {
  const days = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split("T")[0];
    const label = n <= 30
      ? `${d.getDate()} ${d.toLocaleDateString("fr-FR", { month: "short" })}`
      : d.toLocaleDateString("fr-FR", { month: "short", year: "2-digit" });
    days.push({ key, label });
  }
  return days;
}

// Export CSV
function exportCSV(
  stats: DashStats,
  catStats: CatStat[],
  chartData: ChartPoint[],
  periodLabel: string,
) {
  const now = new Date().toLocaleDateString("fr-FR");
  const rows: string[][] = [
    ["Rapport Rizen Backoffice", now, `Période : ${periodLabel}`],
    [],
    ["=== KPIs ==="],
    ["Métrique", "Valeur"],
    ["Utilisateurs total", String(stats.utilisateurs)],
    ["Annonces actives", String(stats.annonces)],
    ["Transactions", String(stats.transactions)],
    ["Volume (FCFA)", String(stats.volume)],
    ["Signalements urgents", String(stats.signalements_urgents)],
    ["Annonces masquées", String(stats.annonces_masquees)],
    ["Traités aujourd'hui", String(stats.resolus_aujourd_hui)],
    [],
    ["=== Catégories ==="],
    ["Catégorie", "Annonces"],
    ...catStats.map((c) => [c.nom, String(c.count)]),
    [],
    ["=== Évolution sur la période ==="],
    ["Date", "Annonces cumulées", "Inscriptions cumulées"],
    ...chartData.map((p) => [p.date, String(p.annonces), String(p.inscriptions)]),
  ];
  const csv = rows.map((r) => r.map((v) => `"${v.replace(/"/g, '""')}"`).join(";")).join("\n");
  const blob = new Blob(["﻿" + csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `rapport-rizen-${new Date().toISOString().split("T")[0]}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

// ─── Types ────────────────────────────────────────────────────────────
interface ActivityItem {
  icon: string;
  color: string;
  title: string;
  sub: string;
  time: string;
}

interface ChartPoint { date: string; annonces: number; inscriptions: number }
interface CatStat { nom: string; count: number }

interface DashStats {
  utilisateurs: number;
  annonces: number;
  transactions: number;
  volume: number;
  signalements_urgents: number;
  annonces_masquees: number;
  resolus_aujourd_hui: number;
}

// ─── KPI card ─────────────────────────────────────────────────────────
function KpiCard({ label, value, badge, sub, icon, highlight }: {
  label: string; value: string; badge: string; sub: string; icon: string; highlight?: boolean;
}) {
  return (
    <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-card flex flex-col gap-3">
      <div className="flex items-start justify-between">
        <span className="text-body-sm text-secondary">{label}</span>
        <div className="w-9 h-9 rounded-full bg-surface-container-high flex items-center justify-center">
          <span className="material-symbols-outlined text-secondary text-[20px]">{icon}</span>
        </div>
      </div>
      <div className="flex items-end gap-3 flex-wrap">
        <span className={`text-[1.9rem] font-bold leading-none tracking-tight ${highlight ? "text-primary-container" : "text-on-secondary-fixed"}`}>{value}</span>
        {badge && (
          <span className="inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full bg-tertiary/10 text-tertiary text-label-sm font-semibold mb-0.5">
            <span className="material-symbols-outlined text-[14px]">trending_up</span>
            {badge}
          </span>
        )}
      </div>
      <p className="text-label-sm text-secondary">{sub}</p>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────
export default function AdminDashboardPage() {
  const router = useRouter();
  const [authLoading, setAuthLoading] = useState(true);
  const [adminName, setAdminName] = useState("Admin");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [periodDays, setPeriodDays] = useState<PeriodDays>(30);
  const [periodOpen, setPeriodOpen] = useState(false);

  const [stats, setStats] = useState<DashStats>({
    utilisateurs: 0, annonces: 0, transactions: 0, volume: 0,
    signalements_urgents: 0, annonces_masquees: 0, resolus_aujourd_hui: 0,
  });
  const [chartData, setChartData] = useState<ChartPoint[]>([]);
  const [catStats, setCatStats] = useState<CatStat[]>([]);
  const [activity, setActivity] = useState<ActivityItem[]>([]);
  const [dataLoading, setDataLoading] = useState(true);

  // ── Auth check ────────────────────────────────────────────────────
  useEffect(() => {
    async function checkAuth() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.replace("/admin/login"); return; }
      const { data: profil } = await supabase.from("profils").select("role, prenom, nom").eq("id", user.id).maybeSingle();
      if (profil?.role !== "superadmin") { await supabase.auth.signOut(); router.replace("/admin/login"); return; }
      setAdminName(`${profil.prenom ?? ""} ${profil.nom ?? ""}`.trim() || "Admin");
      setAuthLoading(false);
      loadDashboard(30);
    }
    checkAuth();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Load all dashboard data ────────────────────────────────────────
  async function loadDashboard(n: PeriodDays = periodDays) {
    setDataLoading(true);
    const days = lastNDays(n);
    const since = days[0].key + "T00:00:00Z";
    const todayKey = days[days.length - 1].key;

    const [
      usersRes, annoncesFullRes, annoncesRecentRes,
      profilsRecentRes, sigsUrgentRes, sigsTodayRes,
      transRes, annonceMasqRes,
    ] = await Promise.all([
      supabase.from("profils").select("id", { count: "exact", head: true }).not("prenom", "is", null),
      supabase.from("annonces").select("id, categorie_id, categories(nom)").eq("statut", "active"),
      supabase.from("annonces").select("id, titre, created_at, ville, quartier, prix_actuel, utilisateur_id").eq("statut", "active").gte("created_at", since).order("created_at", { ascending: false }),
      supabase.from("profils").select("id, prenom, nom, created_at").gte("created_at", since).order("created_at", { ascending: false }),
      supabase.from("signalements").select("id", { count: "exact", head: true }).eq("statut", "en_attente"),
      supabase.from("signalements").select("id", { count: "exact", head: true }).gte("created_at", todayKey + "T00:00:00Z"),
      supabase.from("transactions").select("id, montant", { count: "exact" }),
      supabase.from("annonces").select("id", { count: "exact", head: true }).neq("statut", "active"),
    ]);

    // ── KPIs ──
    const transData = transRes.data ?? [];
    const volume = transData.reduce((s, t) => s + (t.montant ?? 0), 0);

    setStats({
      utilisateurs: usersRes.count ?? 0,
      annonces: annoncesFullRes.data?.length ?? 0,
      transactions: transRes.count ?? 0,
      volume,
      signalements_urgents: sigsUrgentRes.count ?? 0,
      annonces_masquees: annonceMasqRes.count ?? 0,
      resolus_aujourd_hui: sigsTodayRes.count ?? 0,
    });

    // ── Catégories ──
    const allAnnonces = annoncesFullRes.data ?? [];
    const catMap: Record<string, number> = {};
    allAnnonces.forEach((a) => {
      const nom = (a.categories as unknown as { nom: string } | null)?.nom ?? "Autres";
      catMap[nom] = (catMap[nom] ?? 0) + 1;
    });
    setCatStats(
      Object.entries(catMap).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([nom, count]) => ({ nom, count }))
    );

    // ── Chart ──
    const annoncesByDay: Record<string, number> = {};
    (annoncesRecentRes.data ?? []).forEach((a) => {
      const day = a.created_at?.split("T")[0] ?? "";
      if (day) annoncesByDay[day] = (annoncesByDay[day] ?? 0) + 1;
    });
    const inscByDay: Record<string, number> = {};
    (profilsRecentRes.data ?? []).forEach((p) => {
      const day = p.created_at?.split("T")[0] ?? "";
      if (day) inscByDay[day] = (inscByDay[day] ?? 0) + 1;
    });

    // Cumulative counts — sample ~12 points across the period
    const step = Math.max(1, Math.floor(days.length / 12));
    let cumAnnonces = 0;
    let cumInsc = 0;
    const chart: ChartPoint[] = days
      .filter((_, i) => i % step === 0 || i === days.length - 1)
      .map((d) => {
        cumAnnonces += annoncesByDay[d.key] ?? 0;
        cumInsc += inscByDay[d.key] ?? 0;
        return { date: d.label, annonces: cumAnnonces, inscriptions: cumInsc };
      });
    setChartData(chart);

    // ── Activity feed ──
    const recentAnnonces = (annoncesRecentRes.data ?? []).slice(0, 3);
    const recentProfils = (profilsRecentRes.data ?? []).slice(0, 2);

    const sigsFeedRes = await supabase
      .from("signalements")
      .select("id, raison, description, created_at, annonce_id, annonces(titre)")
      .eq("statut", "en_attente")
      .order("created_at", { ascending: false })
      .limit(2);

    const feed: ActivityItem[] = [];

    (sigsFeedRes.data ?? []).forEach((s) => {
      const titre = (s.annonces as unknown as { titre: string } | null)?.titre ?? "une annonce";
      feed.push({
        icon: "report",
        color: "bg-error/10 text-error",
        title: `Signalement : ${s.raison ?? "Contenu suspect"} sur ${titre}`,
        sub: s.description ?? "",
        time: timeAgo(s.created_at),
      });
    });

    recentProfils.forEach((p) => {
      feed.push({
        icon: "verified_user",
        color: "bg-tertiary/10 text-tertiary",
        title: `Nouvel utilisateur : ${p.prenom ?? ""} ${p.nom ?? ""}`.trim(),
        sub: "Compte créé sur la plateforme",
        time: timeAgo(p.created_at),
      });
    });

    recentAnnonces.forEach((a) => {
      feed.push({
        icon: "storefront",
        color: "bg-primary-container/10 text-primary-container",
        title: `Annonce publiée : ${a.titre}`,
        sub: `${a.quartier ? a.quartier + ", " : ""}${a.ville ?? "Dakar"} • ${new Intl.NumberFormat("fr-FR").format(a.prix_actuel)} FCFA`,
        time: timeAgo(a.created_at),
      });
    });

    feed.sort((a, b) => 0); // already ordered by recency from queries
    setActivity(feed.slice(0, 4));
    setDataLoading(false);
  }

  async function handleLogout() {
    await supabase.auth.signOut();
    router.replace("/admin/login");
  }

  // ── Loading screen ────────────────────────────────────────────────
  if (authLoading) {
    return (
      <div className="min-h-screen bg-on-secondary-fixed flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <span className="material-symbols-outlined text-primary-container text-[48px] animate-spin">progress_activity</span>
          <p className="text-secondary-fixed-dim text-label-md">Vérification des droits…</p>
        </div>
      </div>
    );
  }

  const totalCat = catStats.reduce((s, c) => s + c.count, 0) || 1;
  const BAR_COLORS = ["bg-primary-container", "bg-on-secondary-fixed", "bg-tertiary-container", "bg-secondary-fixed", "bg-surface-container-highest"];
  const TEXT_COLORS = ["text-primary-container", "text-on-secondary-fixed", "text-tertiary", "text-secondary-fixed-dim", "text-secondary"];

  return (
    <div className="min-h-screen bg-surface flex overflow-hidden">

      {/* Mobile overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-on-secondary-fixed/60 z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* ── Sidebar — fixed height, logout always visible ── */}
      <aside className={`
        fixed lg:sticky lg:top-0 inset-y-0 left-0 z-50
        w-[220px] h-screen bg-on-secondary-fixed
        flex flex-col shrink-0
        transition-transform duration-300
        ${sidebarOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}
      `}>
        {/* Logo */}
        <div className="px-5 pt-5 pb-4 border-b border-secondary/20 shrink-0">
          <div className="rounded-[8px] overflow-hidden w-fit mb-1">
            <Image src="/Rizen.png" alt="Rizen" width={90} height={32} className="h-8 w-auto object-contain" priority />
          </div>
          <p className="text-label-sm text-secondary-fixed-dim mt-1">Admin Console</p>
        </div>

        {/* Nav — scrollable si besoin */}
        <nav className="flex-1 overflow-y-auto py-3 space-y-0.5">
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 mx-3 px-3 py-2.5 rounded-xl text-label-md transition-colors ${
                item.active
                  ? "bg-primary-container text-white font-semibold"
                  : "text-secondary-fixed-dim hover:bg-surface-container-lowest/10 hover:text-on-secondary"
              }`}
            >
              <span className="material-symbols-outlined text-[20px]">{item.icon}</span>
              {item.label}
            </Link>
          ))}
        </nav>

        {/* Logout — toujours en bas */}
        <div className="px-4 py-4 border-t border-secondary/20 shrink-0 flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-primary-container/20 flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-primary-container text-[18px]">admin_panel_settings</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-label-md text-on-secondary font-semibold truncate">{adminName}</p>
            <p className="text-label-sm text-tertiary-fixed">Superadmin</p>
          </div>
          <button onClick={handleLogout} title="Déconnexion" className="text-secondary-fixed-dim hover:text-error transition-colors shrink-0">
            <span className="material-symbols-outlined text-[20px]">logout</span>
          </button>
        </div>
      </aside>

      {/* ── Main content ── */}
      <div className="flex-1 min-w-0 flex flex-col h-screen overflow-y-auto">

        {/* Top bar */}
        <header className="bg-surface-container-lowest border-b border-surface-container-highest px-4 sm:px-6 h-14 flex items-center justify-between gap-4 sticky top-0 z-30 shrink-0">
          <div className="flex items-center gap-3">
            <button onClick={() => setSidebarOpen(true)} className="lg:hidden text-secondary hover:text-on-surface">
              <span className="material-symbols-outlined text-[24px]">menu</span>
            </button>
            <nav className="hidden sm:flex items-center gap-1 text-label-sm text-secondary">
              <span>Administration</span>
              <span className="material-symbols-outlined text-[14px]">chevron_right</span>
              <span className="text-on-surface font-semibold">Rizen Backoffice</span>
            </nav>
          </div>
          <div className="flex items-center gap-3">
            <div className="hidden sm:flex items-center gap-1.5 h-9 px-3 rounded-full bg-surface-container text-label-sm text-secondary">
              <span className="material-symbols-outlined text-[16px]">calendar_month</span>
              {new Date().toLocaleDateString("fr-FR", { month: "long", year: "numeric" })}
            </div>
            <div className="relative">
              <button className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-secondary hover:bg-surface-container-high transition-colors">
                <span className="material-symbols-outlined text-[20px]">notifications</span>
              </button>
              {stats.signalements_urgents > 0 && (
                <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-error text-white text-[10px] font-bold flex items-center justify-center">
                  {stats.signalements_urgents}
                </span>
              )}
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 p-4 sm:p-6 space-y-6">

          {/* Title */}
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-label-sm text-secondary uppercase tracking-wider mb-1">
                CONSOLE CENTRALE <span className="text-primary-container">•</span> PLATEFORME DAKAR &amp; RÉGIONS
              </p>
              <h1 className="text-[1.75rem] font-bold text-on-secondary-fixed tracking-tight">Tableau de bord Superadmin</h1>
            </div>
            <div className="flex items-center gap-3">

              {/* ── Filtre période ── */}
              <div className="relative">
                <button
                  onClick={() => setPeriodOpen((o) => !o)}
                  className="inline-flex items-center gap-1.5 h-9 px-4 rounded-full bg-surface-container text-label-md text-secondary hover:bg-surface-container-high transition-colors"
                >
                  <span className="material-symbols-outlined text-[16px]">filter_list</span>
                  {PERIODS.find((p) => p.value === periodDays)?.label ?? "Période"}
                  <span className={`material-symbols-outlined text-[16px] transition-transform duration-200 ${periodOpen ? "rotate-180" : ""}`}>expand_more</span>
                </button>

                {periodOpen && (
                  <>
                    {/* overlay to close */}
                    <div className="fixed inset-0 z-40" onClick={() => setPeriodOpen(false)} />
                    <div className="absolute right-0 top-[calc(100%+6px)] z-50 bg-surface-container-lowest rounded-2xl shadow-[0_8px_32px_rgba(0,0,0,0.15)] py-1.5 min-w-[180px] border border-surface-container-highest overflow-hidden">
                      {PERIODS.map((p) => (
                        <button
                          key={p.value}
                          onClick={() => {
                            setPeriodDays(p.value);
                            setPeriodOpen(false);
                            loadDashboard(p.value);
                          }}
                          className={`w-full flex items-center gap-2.5 px-4 py-2.5 text-label-md text-left hover:bg-surface-container-low transition-colors ${
                            periodDays === p.value ? "text-primary-container font-semibold" : "text-on-surface"
                          }`}
                        >
                          {periodDays === p.value && (
                            <span className="material-symbols-outlined text-[16px] text-primary-container">check</span>
                          )}
                          {periodDays !== p.value && <span className="w-[16px]" />}
                          {p.label}
                        </button>
                      ))}
                    </div>
                  </>
                )}
              </div>

              {/* ── Export CSV ── */}
              <button
                onClick={() => exportCSV(stats, catStats, chartData, PERIODS.find((p) => p.value === periodDays)?.label ?? "")}
                disabled={dataLoading}
                className="inline-flex items-center gap-1.5 h-9 px-4 rounded-full bg-primary-container text-white text-label-md font-semibold hover:opacity-90 transition-all disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-[16px]">download</span>
                Exporter CSV
              </button>

            </div>
          </div>

          {/* KPI cards */}
          {dataLoading ? (
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="bg-surface-container-lowest rounded-2xl p-5 shadow-card animate-pulse h-32" />
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <KpiCard label="Utilisateurs total" value={fmt(stats.utilisateurs)} badge="+12%" sub="Actifs sur la plateforme" icon="person" />
              <KpiCard label="Annonces actives" value={fmt(stats.annonces)} badge="+8.4%" sub="98% validées par modération" icon="storefront" />
              <KpiCard label="Transactions ce mois" value={fmt(stats.transactions)} badge="+21% vs M-1" sub="Garantie séquestre Rizen Pay" icon="payments" highlight />
              <KpiCard
                label="Volume total"
                value={stats.volume >= 1_000_000 ? (stats.volume / 1_000_000).toFixed(1) + "M FCFA" : fmt(stats.volume) + " FCFA"}
                badge="+18.5%"
                sub={"Moyenne : " + (stats.transactions > 0 ? fmt(Math.round(stats.volume / stats.transactions)) : "—") + " FCFA / vente"}
                icon="account_balance"
              />
            </div>
          )}

          {/* Chart + Categories */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

            {/* Chart */}
            <div className="lg:col-span-2 bg-surface-container-lowest rounded-2xl shadow-card p-5">
              <div className="mb-4">
                <h2 className="text-label-lg text-on-secondary-fixed font-bold">Inscriptions &amp; Annonces</h2>
                <p className="text-label-sm text-secondary">Dynamique quotidienne — 30 derniers jours</p>
              </div>
              {dataLoading ? (
                <div className="h-[260px] bg-surface-container animate-pulse rounded-xl" />
              ) : chartData.length === 0 ? (
                <div className="h-[260px] flex items-center justify-center text-secondary text-body-sm">Aucune donnée récente</div>
              ) : (
                <ResponsiveContainer width="100%" height={260}>
                  <AreaChart data={chartData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="gradA" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#FC7138" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#FC7138" stopOpacity={0} />
                      </linearGradient>
                      <linearGradient id="gradI" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#131b2d" stopOpacity={0.2} />
                        <stop offset="95%" stopColor="#131b2d" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e3e2e2" />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: "#565e73" }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 11, fill: "#565e73" }} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={{ background: "#fff", border: "none", borderRadius: "12px", boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }} labelStyle={{ fontWeight: 700, color: "#131b2d" }} />
                    <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: "12px" }} />
                    <Area type="monotone" dataKey="annonces" name="Annonces" stroke="#FC7138" strokeWidth={2.5} fill="url(#gradA)" dot={false} activeDot={{ r: 5 }} />
                    <Area type="monotone" dataKey="inscriptions" name="Inscriptions" stroke="#131b2d" strokeWidth={2} fill="url(#gradI)" dot={false} activeDot={{ r: 4 }} />
                  </AreaChart>
                </ResponsiveContainer>
              )}
            </div>

            {/* Categories */}
            <div className="bg-surface-container-lowest rounded-2xl shadow-card p-5">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h2 className="text-label-lg text-on-secondary-fixed font-bold">Annonces par catégorie</h2>
                  <p className="text-label-sm text-secondary">Volume actuel des {fmt(stats.annonces)} items</p>
                </div>
                <span className="text-label-sm text-primary-container font-semibold">Répartition</span>
              </div>
              {dataLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => <div key={i} className="h-6 bg-surface-container animate-pulse rounded-full" />)}
                </div>
              ) : (
                <>
                  <div className="flex h-3 rounded-full overflow-hidden mb-5">
                    {catStats.map((c, i) => (
                      <div key={c.nom} className={BAR_COLORS[i]} style={{ width: `${(c.count / totalCat) * 100}%` }} />
                    ))}
                  </div>
                  <div className="space-y-3">
                    {catStats.map((c, i) => (
                      <div key={c.nom} className="flex items-center gap-2">
                        <span className={`w-3 h-3 rounded-full shrink-0 ${BAR_COLORS[i]}`} />
                        <span className={`text-body-sm flex-1 truncate ${TEXT_COLORS[i]}`}>{c.nom}</span>
                        <span className="text-label-md text-on-surface font-semibold shrink-0">{fmt(c.count)}</span>
                        <span className="text-label-sm text-secondary w-8 text-right shrink-0">{Math.round((c.count / totalCat) * 100)}%</span>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          </div>

          {/* Activity + Moderation */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {/* Activity feed */}
            <div className="bg-surface-container-lowest rounded-2xl shadow-card p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-tertiary-container animate-pulse" />
                  <h2 className="text-label-lg text-on-secondary-fixed font-bold">Activité récente en direct</h2>
                </div>
                <span className="text-label-sm text-secondary">Flux temps réel</span>
              </div>
              {dataLoading ? (
                <div className="space-y-4">
                  {[...Array(3)].map((_, i) => <div key={i} className="h-14 bg-surface-container animate-pulse rounded-xl" />)}
                </div>
              ) : activity.length === 0 ? (
                <p className="text-body-sm text-secondary text-center py-8">Aucune activité récente</p>
              ) : (
                <div className="space-y-4">
                  {activity.map((a, i) => (
                    <div key={i} className="flex gap-3">
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 ${a.color}`}>
                        <span className="material-symbols-outlined text-[18px]">{a.icon}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <p className="text-label-md text-on-surface font-semibold leading-tight line-clamp-1">{a.title}</p>
                          <span className="text-label-sm text-secondary shrink-0 whitespace-nowrap">{a.time}</span>
                        </div>
                        <p className="text-body-sm text-secondary mt-0.5 truncate">{a.sub}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Moderation */}
            <div className="bg-surface-container-lowest rounded-2xl shadow-card p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-[20px] text-primary-container">shield</span>
                  <h2 className="text-label-lg text-on-secondary-fixed font-bold">Modération &amp; Litiges</h2>
                </div>
                <span className="px-2.5 py-0.5 rounded-full bg-tertiary/10 text-tertiary text-label-sm font-semibold">Équipe active</span>
              </div>

              {dataLoading ? (
                <div className="h-32 bg-surface-container animate-pulse rounded-2xl mb-4" />
              ) : (
                <div className="grid grid-cols-3 gap-3 mb-5">
                  <div className="bg-error-container/30 rounded-2xl p-4 text-center">
                    <p className="text-[1.75rem] font-bold text-on-secondary-fixed">{stats.signalements_urgents}</p>
                    <p className="text-label-sm text-secondary mt-0.5">Signalements</p>
                    <p className="text-label-sm text-error font-semibold">Urgent</p>
                  </div>
                  <div className="bg-surface-container rounded-2xl p-4 text-center">
                    <p className="text-[1.75rem] font-bold text-on-secondary-fixed">{stats.annonces_masquees}</p>
                    <p className="text-label-sm text-secondary mt-0.5">Masquées</p>
                    <p className="text-label-sm text-secondary font-semibold">Revue</p>
                  </div>
                  <div className="bg-surface-container rounded-2xl p-4 text-center">
                    <p className="text-[1.75rem] font-bold text-on-secondary-fixed">{stats.resolus_aujourd_hui}</p>
                    <p className="text-label-sm text-secondary mt-0.5">Traités</p>
                    <p className="text-label-sm text-secondary font-semibold">Aujourd&apos;hui</p>
                  </div>
                </div>
              )}

              <div className="mb-5">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-label-md text-on-surface">Taux de résolution (Objectif &gt; 90%)</p>
                  <span className="text-label-md text-tertiary font-bold">
                    {stats.signalements_urgents + stats.resolus_aujourd_hui > 0
                      ? Math.round((stats.resolus_aujourd_hui / (stats.signalements_urgents + stats.resolus_aujourd_hui)) * 100) + "%"
                      : "—"}
                  </span>
                </div>
                <div className="h-2.5 rounded-full bg-surface-container-high overflow-hidden">
                  <div
                    className="h-full bg-tertiary-container rounded-full transition-all duration-700"
                    style={{
                      width: stats.signalements_urgents + stats.resolus_aujourd_hui > 0
                        ? `${Math.round((stats.resolus_aujourd_hui / (stats.signalements_urgents + stats.resolus_aujourd_hui)) * 100)}%`
                        : "0%",
                    }}
                  />
                </div>
                <div className="flex justify-between mt-1.5 text-label-sm text-secondary">
                  <span>En attente : {stats.signalements_urgents}</span>
                  <span>Traités : {stats.resolus_aujourd_hui}</span>
                </div>
              </div>

              <Link
                href="/admin/signalements"
                className="flex items-center justify-center gap-2 w-full h-[52px] rounded-full bg-primary-container text-white text-label-lg font-semibold hover:opacity-90 transition-all"
              >
                Ouvrir la file des signalements
                <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
              </Link>
            </div>
          </div>

        </main>
      </div>
    </div>
  );
}
