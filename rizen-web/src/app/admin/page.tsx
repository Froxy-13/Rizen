import { LayoutDashboard, FileText, Users, Flag, Scale, Tag, BarChart3, LogOut, TrendingUp, TrendingDown, AlertCircle } from "lucide-react";

const NAV_ITEMS = [
  { icon: LayoutDashboard, label: "Vue d'ensemble", active: true },
  { icon: FileText, label: "Annonces" },
  { icon: Users, label: "Utilisateurs" },
  { icon: Flag, label: "Signalements", badge: 3 },
  { icon: Scale, label: "Litiges", badge: 1 },
  { icon: Tag, label: "Catégories" },
  { icon: BarChart3, label: "Statistiques" },
];

const KPI = [
  { label: "Utilisateurs", value: "8 542", growth: 12, color: "text-rizen-link", bg: "bg-rizen-link/10" },
  { label: "Annonces actives", value: "1 247", growth: 8, color: "text-rizen-success", bg: "bg-rizen-success/10" },
  { label: "Transactions (mois)", value: "234", growth: -3, color: "text-primary", bg: "bg-primary/10" },
  { label: "Volume (FCFA)", value: "47 200 000", growth: 15, color: "text-navy", bg: "bg-navy/10" },
];

const ACTIVITY = [
  { type: "signalement", icon: "🚩", color: "bg-rizen-error/10 text-rizen-error", title: "Signalement", sub: "iPhone 14 Pro — Suspicion d'arnaque", time: "il y a 5 min" },
  { type: "user", icon: "👤", color: "bg-rizen-success/10 text-rizen-success", title: "Nouvel utilisateur", sub: "Awa Ndiaye — Dakar", time: "il y a 12 min" },
  { type: "annonce", icon: "📋", color: "bg-rizen-link/10 text-rizen-link", title: "Annonce publiée", sub: "Frigo Samsung 400L - Thiès", time: "il y a 23 min" },
  { type: "user", icon: "👤", color: "bg-rizen-success/10 text-rizen-success", title: "Nouvel utilisateur", sub: "Ibrahima Fall — Saint-Louis", time: "il y a 38 min" },
  { type: "signalement", icon: "🚩", color: "bg-rizen-error/10 text-rizen-error", title: "Signalement", sub: "Moto Yamaha — Contrefaçon", time: "il y a 1h" },
];

export default function AdminDashboard() {
  return (
    <div className="flex h-screen bg-rizen-bg overflow-hidden">
      {/* Sidebar */}
      <aside className="w-60 flex-shrink-0 bg-navy flex flex-col">
        <div className="p-6 border-b border-white/10">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white font-bold text-sm">R</div>
            <div>
              <span className="font-bold text-white text-sm">Rizen</span>
              <span className="ml-2 text-[10px] font-bold bg-primary/20 text-primary px-2 py-0.5 rounded-full uppercase tracking-wide">Admin</span>
            </div>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {NAV_ITEMS.map((item) => (
            <button
              key={item.label}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                item.active
                  ? "bg-primary/15 text-primary border-l-[3px] border-primary pl-[9px]"
                  : "text-white/60 hover:text-white hover:bg-white/5"
              }`}
            >
              <item.icon className="w-4 h-4 flex-shrink-0" />
              <span className="flex-1 text-left">{item.label}</span>
              {item.badge && (
                <span className="bg-rizen-error text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full tabular-nums">
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-white/10">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm">S</div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-xs font-semibold truncate">Super Admin</p>
              <p className="text-white/40 text-[11px] truncate">admin@rizen.sn</p>
            </div>
          </div>
          <button className="w-full flex items-center gap-2 text-white/50 hover:text-white text-xs transition-colors px-1">
            <LogOut className="w-3.5 h-3.5" />
            Déconnexion
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="bg-white border-b border-rizen-border h-14 flex items-center justify-between px-6 flex-shrink-0">
          <div>
            <p className="text-xs text-rizen-muted">Rizen Admin</p>
            <p className="text-sm font-semibold text-navy leading-none">Vue d&apos;ensemble</p>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-rizen-muted bg-rizen-surface-low px-3 py-1.5 rounded-full">Novembre 2026</span>
            <button className="relative w-8 h-8 rounded-full bg-rizen-surface-low flex items-center justify-center text-rizen-muted hover:text-navy transition-colors">
              <AlertCircle className="w-4 h-4" />
              <span className="absolute top-0 right-0 w-2 h-2 bg-rizen-error rounded-full" />
            </button>
          </div>
        </header>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* KPI tiles */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {KPI.map((k) => (
              <div key={k.label} className="card p-5">
                <div className={`w-10 h-10 rounded-xl ${k.bg} flex items-center justify-center mb-4`}>
                  <span className={`text-lg ${k.color}`}>📊</span>
                </div>
                <p className={`text-2xl font-bold tabular-nums ${k.color} mb-1`}>{k.value}</p>
                <p className="text-xs text-rizen-muted font-medium mb-2">{k.label}</p>
                <div className={`flex items-center gap-1 text-xs font-semibold ${k.growth >= 0 ? "text-rizen-success" : "text-rizen-error"}`}>
                  {k.growth >= 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                  {Math.abs(k.growth)}% ce mois
                </div>
              </div>
            ))}
          </div>

          {/* Charts + Activity */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Chart placeholder */}
            <div className="lg:col-span-2 card p-6">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="font-semibold text-navy text-sm">Inscriptions — 30 derniers jours</h3>
                  <p className="text-rizen-muted text-xs mt-0.5">Nouveaux utilisateurs par jour</p>
                </div>
                <span className="text-xs font-semibold text-rizen-success bg-rizen-success/10 px-2.5 py-1 rounded-full">+12% ce mois</span>
              </div>
              {/* Zone graphique */}
              <div className="h-40 bg-rizen-surface-low rounded-xl flex items-center justify-center">
                <p className="text-rizen-muted text-xs">Graphique recharts — à connecter</p>
              </div>
            </div>

            {/* Modération */}
            <div className="card p-6 space-y-5">
              <div>
                <h3 className="font-semibold text-navy text-sm mb-1">Aperçu Modération</h3>
                <p className="text-rizen-muted text-xs">État actuel</p>
              </div>
              <div className="space-y-3">
                {[
                  { label: "Signalements en attente", value: "3", color: "text-rizen-error" },
                  { label: "Annonces masquées", value: "7", color: "text-yellow-500" },
                  { label: "Litiges ouverts", value: "1", color: "text-rizen-error" },
                ].map((item) => (
                  <div key={item.label} className="flex items-center justify-between">
                    <span className="text-xs text-rizen-muted">{item.label}</span>
                    <span className={`text-sm font-bold tabular-nums ${item.color}`}>{item.value}</span>
                  </div>
                ))}
              </div>
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-rizen-muted">Taux de traitement</span>
                  <span className="text-xs font-bold text-rizen-success">94%</span>
                </div>
                <div className="h-2 bg-rizen-surface-low rounded-full overflow-hidden">
                  <div className="h-full bg-rizen-success rounded-full" style={{ width: "94%" }} />
                </div>
              </div>
              <button className="text-primary text-xs font-semibold hover:underline">
                Voir tous les signalements →
              </button>
            </div>
          </div>

          {/* Activité récente */}
          <div className="card p-6">
            <h3 className="font-semibold text-navy text-sm mb-5">Activité récente</h3>
            <div className="space-y-4">
              {ACTIVITY.map((item, i) => (
                <div key={i} className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-xl ${item.color} flex items-center justify-center text-sm flex-shrink-0`}>
                    {item.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-navy">{item.title}</p>
                    <p className="text-xs text-rizen-muted truncate">{item.sub}</p>
                  </div>
                  <span className="text-[11px] text-rizen-muted flex-shrink-0">{item.time}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
