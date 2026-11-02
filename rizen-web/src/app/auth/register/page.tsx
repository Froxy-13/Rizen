"use client";

import { useState, useEffect, useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

// ── Barre de force du mot de passe ──────────────────────────────────
function PasswordStrength({ password }: { password: string }) {
  if (!password) return null;

  let score = 0;
  if (password.length >= 6) score++;
  if (password.length >= 10) score++;
  if (/[A-Z]/.test(password) && /[0-9]/.test(password)) score++;
  if (/[^A-Za-z0-9]/.test(password)) score++;

  const segmentColors = [
    "bg-surface-container-highest",
    "bg-error",
    "bg-primary-container",
    "bg-on-primary-fixed-variant",
    "bg-tertiary",
  ];
  const labels = ["Très faible", "Faible", "Moyen", "Bon", "Sécurisé"];
  const labelColors = [
    "text-secondary",
    "text-error",
    "text-primary-container",
    "text-on-primary-fixed-variant",
    "text-tertiary",
  ];

  return (
    <div className="space-y-1 pt-1">
      <div className="grid grid-cols-4 gap-2 h-1.5 w-full">
        {[1, 2, 3, 4].map((i) => (
          <div
            key={i}
            className={`h-full rounded-full transition-colors duration-300 ${
              i <= score ? segmentColors[score] : "bg-surface-container-highest"
            }`}
          />
        ))}
      </div>
      <div className="flex justify-between items-center">
        <span className="text-label-sm text-secondary">Force du mot de passe :</span>
        <span className={`text-label-sm font-semibold ${labelColors[score]}`}>{labels[score]}</span>
      </div>
    </div>
  );
}

// ── Page principale ──────────────────────────────────────────────────
export default function RegisterPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    prenom: "", nom: "", email: "", telephone: "", adresse: "", password: "",
  });
  const [showPassword, setShowPassword] = useState(false);
  const [accepted, setAccepted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [vendeurs, setVendeurs] = useState<number | null>(null);
  const [mouse, setMouse] = useState({ x: 0, y: 0 });
  const leftRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    supabase
      .from("profils")
      .select("id", { count: "exact", head: true })
      .not("prenom", "is", null)
      .then(({ count }) => { if (count !== null) setVendeurs(count); });
  }, []);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const el = leftRef.current;
      if (!el) return;
      const r = el.getBoundingClientRect();
      setMouse({
        x: (e.clientX - r.left) / r.width - 0.5,
        y: (e.clientY - r.top) / r.height - 0.5,
      });
    };
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, []);

  const set = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm((f) => ({ ...f, [field]: e.target.value }));

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!accepted) { setError("Veuillez accepter les conditions d'utilisation."); return; }
    setError("");
    setLoading(true);
    try {
      const { error } = await supabase.auth.signUp({
        email: form.email,
        password: form.password,
        options: {
          data: { nom: form.nom, prenom: form.prenom, telephone: form.telephone, adresse: form.adresse },
        },
      });
      if (error) throw error;
      router.push("/decouvrir");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Erreur lors de l'inscription.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/decouvrir` },
    });
  };

  const px = mouse.x;
  const py = mouse.y;

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4 md:p-8 lg:p-12">
      <div className="w-full max-w-[1440px] overflow-hidden rounded-[2rem] shadow-2xl flex flex-col lg:flex-row">

        {/* ── Panneau gauche ── */}
        <div
          ref={leftRef}
          className="relative w-full lg:w-[40%] bg-on-secondary-fixed p-8 lg:p-14 flex flex-col justify-between overflow-hidden"
        >
          {/* Blobs ambiants parallaxe */}
          <div
            className="absolute -top-32 -left-32 w-80 h-80 rounded-full bg-primary-container/15 blur-3xl pointer-events-none"
            style={{
              transform: `translate(${px * 30}px, ${py * 30}px)`,
              transition: "transform 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          />
          <div
            className="absolute -bottom-24 -right-24 w-96 h-96 rounded-full bg-tertiary-container/10 blur-3xl pointer-events-none"
            style={{
              transform: `translate(${px * -20}px, ${py * -20}px)`,
              transition: "transform 0.5s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          />

          {/* Branding en haut */}
          <div className="relative z-10 space-y-8">
            <div className="rounded-[10px] overflow-hidden w-fit">
              <Image src="/R.png" alt="Rizen" width={40} height={40} className="h-10 w-auto object-contain" />
            </div>

            <div className="space-y-4 pt-2">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-surface-container-lowest/10 backdrop-blur-md">
                <span className="w-2 h-2 rounded-full bg-tertiary-container animate-pulse" />
                <span className="text-label-sm text-tertiary-fixed font-semibold tracking-wide uppercase">
                  Teranga Confiante
                </span>
              </div>

              <h1 className="text-display-lg leading-tight tracking-tight text-surface-container-lowest">
                Vendez et achetez en toute sérénité.
              </h1>

              <p className="text-body-lg text-surface-container-high/80 leading-relaxed font-normal">
                Le marché digital de référence reliant particuliers et commerçants vérifiés à travers tout le Sénégal.
              </p>
            </div>
          </div>

          {/* Carte statistique communautaire */}
          <div
            className="relative z-10 my-10 p-6 rounded-2xl bg-surface-container-lowest/5 backdrop-blur-lg space-y-4"
            style={{
              transform: `translate(${px * 8}px, ${py * 8}px)`,
              transition: "transform 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          >
            <div className="flex items-center gap-4">
              <div className="flex -space-x-3">
                <div className="inline-flex h-11 w-11 rounded-full ring-2 ring-on-secondary-fixed bg-surface-container-high items-center justify-center text-on-surface">
                  <span className="material-symbols-outlined text-[20px]">public</span>
                </div>
                <div className="inline-flex h-11 w-11 rounded-full ring-2 ring-on-secondary-fixed bg-primary-container items-center justify-center text-surface-container-lowest">
                  <span className="material-symbols-outlined text-[20px]">person</span>
                </div>
                <div className="inline-flex h-11 w-11 rounded-full ring-2 ring-on-secondary-fixed bg-tertiary-container items-center justify-center text-surface-container-lowest">
                  <span className="material-symbols-outlined text-[20px]">verified</span>
                </div>
              </div>
              <div>
                <div className="text-headline-md font-bold text-surface-container-lowest tracking-tight">
                  {vendeurs !== null
                    ? new Intl.NumberFormat("fr-FR").format(vendeurs) + "+"
                    : "8 500+"}
                </div>
                <div className="text-body-sm text-surface-variant font-medium">Vendeurs certifiés actifs</div>
              </div>
            </div>
            <p className="text-body-sm text-surface-container-high/80 leading-snug">
              Présents à <strong className="text-surface-container-lowest">Dakar</strong> et partout en région pour des remises en mains propres en toute confiance.
            </p>
          </div>

          {/* Badges de confiance */}
          <div className="relative z-10 flex flex-col gap-2.5">
            <div
              className="inline-flex items-center gap-2 bg-surface-container-lowest/8 px-3.5 py-2 rounded-full text-secondary-fixed-dim text-label-md w-fit"
              style={{
                transform: `translate(${px * 8}px, ${py * 8}px)`,
                transition: "transform 0.35s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <div className="w-7 h-7 rounded-full bg-primary-container/20 flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-primary-container text-[16px]">lock</span>
              </div>
              Paiement sécurisé Wave &amp; Orange Money
            </div>
            <div
              className="inline-flex items-center gap-2 bg-surface-container-lowest/8 px-3.5 py-2 rounded-full text-secondary-fixed-dim text-label-md w-fit"
              style={{
                transform: `translate(${px * -12}px, ${py * 12}px)`,
                transition: "transform 0.45s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <div className="w-7 h-7 rounded-full bg-tertiary-container/20 flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-tertiary-fixed text-[16px]">verified_user</span>
              </div>
              Profils vérifiés avec carte d&apos;identité
            </div>
            <div
              className="inline-flex items-center gap-2 bg-surface-container-lowest/8 px-3.5 py-2 rounded-full text-secondary-fixed-dim text-label-md w-fit"
              style={{
                transform: `translate(${px * 10}px, ${py * -10}px)`,
                transition: "transform 0.55s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <div className="w-7 h-7 rounded-full bg-secondary-container/20 flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-secondary-fixed text-[16px]">support_agent</span>
              </div>
              Support local 7j/7 basé à Dakar
            </div>
          </div>
        </div>

        {/* ── Panneau droit ── */}
        <div className="relative w-full lg:w-[60%] bg-surface p-6 sm:p-10 lg:p-16 flex flex-col justify-center overflow-hidden">
          {/* Blobs animés derrière le formulaire */}
          <div
            className="absolute top-0 right-0 w-64 h-64 rounded-full bg-primary-fixed/20 blur-3xl pointer-events-none animate-bob"
            style={{ animationDuration: "7s" }}
          />
          <div
            className="absolute bottom-0 left-0 w-56 h-56 rounded-full bg-tertiary-fixed/15 blur-3xl pointer-events-none animate-bob"
            style={{ animationDuration: "10s", animationDelay: "2s" }}
          />

          {/* Lien retour */}
          <div className="relative z-10 flex justify-end mb-6">
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 text-label-md text-secondary hover:text-primary-container transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">arrow_back</span>
              Retour au site
            </Link>
          </div>

          <div className="relative z-10 max-w-[560px] w-full mx-auto space-y-6">
            {/* Titre */}
            <div className="space-y-1.5">
              <h2 className="text-display-lg-mobile lg:text-display-lg font-bold text-on-secondary-fixed tracking-tight">
                Créer un compte
              </h2>
              <p className="text-body-lg text-secondary">
                Rejoignez{" "}
              {vendeurs !== null
                ? new Intl.NumberFormat("fr-FR").format(vendeurs) + "+"
                : "8 500+"}{" "}
              vendeurs et acheteurs au Sénégal
              </p>
            </div>

            {/* Google */}
            <button
              type="button"
              onClick={handleGoogle}
              className="w-full h-[52px] bg-surface-container-lowest hover:bg-surface-container-low transition-all rounded-full flex items-center justify-center gap-3 px-6 shadow-card text-on-secondary-fixed text-body-lg font-semibold active:scale-[0.99]"
            >
              <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
                <path d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.66v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.15z" fill="#4285F4" />
                <path d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.34 24 12 24z" fill="#34A853" />
                <path d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 9.99 0 12s.45 3.82 1.25 5.42l4.03-3.15z" fill="#FBBC05" />
                <path d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.34 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z" fill="#EA4335" />
              </svg>
              S&apos;inscrire avec Google
            </button>

            {/* Séparateur */}
            <div className="relative flex items-center justify-center">
              <div className="w-full h-px bg-surface-variant" />
              <span className="absolute px-4 bg-surface text-label-md text-secondary tracking-wider uppercase">
                ou avec votre email
              </span>
            </div>

            {/* Formulaire */}
            <form onSubmit={handleRegister} className="space-y-4">
              {error && (
                <div className="bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-2xl flex items-center gap-2">
                  <span className="material-symbols-outlined text-[18px]">error</span>
                  {error}
                </div>
              )}

              {/* Prénom & Nom */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-label-md font-semibold text-on-surface" htmlFor="prenom">
                    Prénom <span className="text-primary-container">*</span>
                  </label>
                  <input
                    id="prenom" type="text" placeholder="Moussa" required
                    value={form.prenom} onChange={set("prenom")}
                    className="w-full h-[52px] bg-surface-container-lowest rounded-2xl px-4 text-on-surface text-body-md placeholder:text-secondary/60 shadow-card outline-none focus:ring-2 focus:ring-primary-container transition-all"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-label-md font-semibold text-on-surface" htmlFor="nom">
                    Nom <span className="text-primary-container">*</span>
                  </label>
                  <input
                    id="nom" type="text" placeholder="Diallo" required
                    value={form.nom} onChange={set("nom")}
                    className="w-full h-[52px] bg-surface-container-lowest rounded-2xl px-4 text-on-surface text-body-md placeholder:text-secondary/60 shadow-card outline-none focus:ring-2 focus:ring-primary-container transition-all"
                  />
                </div>
              </div>

              {/* Email */}
              <div className="space-y-1.5">
                <label className="text-label-md font-semibold text-on-surface" htmlFor="email">
                  Adresse email <span className="text-primary-container">*</span>
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-[20px] text-secondary/70 pointer-events-none">mail</span>
                  <input
                    id="email" type="email" placeholder="moussa.diallo@gmail.com" required
                    value={form.email} onChange={set("email")}
                    className="w-full h-[52px] bg-surface-container-lowest rounded-2xl pl-11 pr-4 text-on-surface text-body-md placeholder:text-secondary/60 shadow-card outline-none focus:ring-2 focus:ring-primary-container transition-all"
                  />
                </div>
              </div>

              {/* Téléphone */}
              <div className="space-y-1.5">
                <label className="text-label-md font-semibold text-on-surface" htmlFor="phone">
                  Numéro de téléphone <span className="text-primary-container">*</span>
                </label>
                <div className="relative flex items-center shadow-card rounded-2xl bg-surface-container-lowest focus-within:ring-2 focus-within:ring-primary-container transition-all">
                  <div className="h-[52px] flex items-center gap-1.5 pl-4 pr-3 bg-surface-container-low rounded-l-2xl shrink-0 select-none">
                    <span className="material-symbols-outlined text-[16px] text-on-secondary-fixed/60">flag</span>
                    <span className="text-label-md font-semibold text-on-surface">+221</span>
                  </div>
                  <input
                    id="phone" type="tel" placeholder="77 123 45 67" required
                    value={form.telephone} onChange={set("telephone")}
                    className="w-full h-[52px] bg-transparent rounded-r-2xl px-4 text-on-surface text-body-md placeholder:text-secondary/60 outline-none"
                  />
                </div>
                <p className="text-label-sm text-secondary px-1">
                  Utilisé pour les échanges sécurisés Wave / Orange Money
                </p>
              </div>

              {/* Adresse */}
              <div className="space-y-1.5">
                <label className="text-label-md font-semibold text-on-surface" htmlFor="adresse">
                  Adresse / Ville <span className="text-primary-container">*</span>
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-[20px] text-secondary/70 pointer-events-none">location_on</span>
                  <input
                    id="adresse" type="text" placeholder="Ex: Dakar, Plateau" required
                    value={form.adresse} onChange={set("adresse")}
                    className="w-full h-[52px] bg-surface-container-lowest rounded-2xl pl-11 pr-4 text-on-surface text-body-md placeholder:text-secondary/60 shadow-card outline-none focus:ring-2 focus:ring-primary-container transition-all"
                  />
                </div>
              </div>

              {/* Mot de passe */}
              <div className="space-y-2">
                <label className="text-label-md font-semibold text-on-surface" htmlFor="password">
                  Mot de passe <span className="text-primary-container">*</span>
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-[20px] text-secondary/70 pointer-events-none">lock</span>
                  <input
                    id="password" type={showPassword ? "text" : "password"} placeholder="••••••••••••" required
                    value={form.password} onChange={set("password")}
                    className="w-full h-[52px] bg-surface-container-lowest rounded-2xl pl-11 pr-12 text-on-surface text-body-md placeholder:text-secondary/60 shadow-card outline-none focus:ring-2 focus:ring-primary-container transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-secondary hover:text-on-surface p-1 rounded-full focus:outline-none"
                    aria-label={showPassword ? "Masquer" : "Afficher"}
                  >
                    <span className="material-symbols-outlined text-[20px]">
                      {showPassword ? "visibility_off" : "visibility"}
                    </span>
                  </button>
                </div>
                <PasswordStrength password={form.password} />
              </div>

              {/* CGU */}
              <div className="pt-2">
                <label className="flex items-start gap-3 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={accepted}
                    onChange={(e) => setAccepted(e.target.checked)}
                    className="mt-0.5 w-5 h-5 rounded-md accent-primary-container cursor-pointer"
                  />
                  <span className="text-body-sm text-secondary leading-snug">
                    J&apos;accepte les{" "}
                    <Link href="/conditions-generales" className="text-on-surface font-semibold underline underline-offset-2 hover:text-primary-container">
                      Conditions Générales
                    </Link>{" "}
                    et la{" "}
                    <Link href="/confidentialite" className="text-on-surface font-semibold underline underline-offset-2 hover:text-primary-container">
                      Politique de Confidentialité
                    </Link>{" "}
                    de Rizen.
                  </span>
                </label>
              </div>

              {/* Submit */}
              <div className="pt-3">
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full h-[52px] bg-primary-container hover:bg-primary text-surface-container-lowest text-body-lg font-semibold rounded-full transition-all duration-200 active:scale-[0.99] flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
                  style={{ boxShadow: "0 8px 24px rgba(252, 113, 56, 0.25)" }}
                >
                  {loading ? (
                    <>
                      <span className="material-symbols-outlined text-[20px] animate-spin">progress_activity</span>
                      Création en cours...
                    </>
                  ) : (
                    <>
                      Créer mon compte
                      <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
                    </>
                  )}
                </button>
              </div>
            </form>

            {/* Lien connexion */}
            <div className="text-center pt-2">
              <p className="text-body-md text-secondary">
                Déjà un compte ?{" "}
                <Link
                  href="/auth/login"
                  className="text-primary-container font-semibold hover:underline underline-offset-4 ml-1"
                >
                  Se connecter
                </Link>
              </p>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
