"use client";

import { useState, useEffect, useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { supabase } from "@/lib/supabase";

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get("redirect") || "/feed";
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [mouse, setMouse] = useState({ x: 0, y: 0 });
  const leftRef = useRef<HTMLElement>(null);

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

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      router.push(redirectTo);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Erreur de connexion";
      setError(msg === "Invalid login credentials" ? "Email ou mot de passe incorrect." : msg);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(redirectTo)}` },
    });
  };

  const px = mouse.x;
  const py = mouse.y;

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4 md:p-8 lg:p-12">
      <div className="w-full max-w-6xl overflow-hidden rounded-[2rem] shadow-2xl flex flex-col lg:flex-row">

        {/* ── Panneau gauche — caché sur mobile ── */}
        <aside
          ref={leftRef}
          className="relative hidden lg:flex lg:w-5/12 bg-on-secondary-fixed p-8 lg:p-12 flex-col justify-between overflow-hidden"
        >
          {/* Blobs ambiants parallaxe */}
          <div
            className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-primary-container/15 blur-3xl pointer-events-none"
            style={{
              transform: `translate(${px * 30}px, ${py * 30}px)`,
              transition: "transform 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          />
          <div
            className="absolute -bottom-20 -right-20 w-72 h-72 rounded-full bg-tertiary-container/15 blur-3xl pointer-events-none"
            style={{
              transform: `translate(${px * -20}px, ${py * -20}px)`,
              transition: "transform 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          />
          <div
            className="absolute top-1/2 left-1/2 w-40 h-40 rounded-full bg-secondary-fixed/5 blur-2xl pointer-events-none"
            style={{
              transform: `translate(calc(-50% + ${px * 15}px), calc(-50% + ${py * 15}px))`,
              transition: "transform 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          />

          {/* Branding en haut */}
          <div className="relative z-10 flex flex-col items-start gap-4">
            <div className="rounded-[10px] overflow-hidden">
              <Image
                src="/R.png"
                alt="Rizen"
                width={40}
                height={40}
                className="h-10 w-auto object-contain"
              />
            </div>
            <p className="text-headline-md text-surface tracking-tight max-w-sm mt-2">
              Votre marketplace de confiance au Sénégal.
            </p>
            <p className="text-body-md text-secondary-fixed-dim">
              Achetez, vendez et échangez en toute sérénité à Dakar et partout au pays.
            </p>
          </div>

          {/* Cartes produits flottantes */}
          <div className="relative z-10 my-8 flex flex-col gap-3">
            {/* Carte 1 */}
            <div
              className="rounded-2xl bg-surface-container-lowest/10 backdrop-blur-md p-3.5 shadow-lg flex items-center gap-3.5"
              style={{
                transform: `rotate(-1deg) translate(${px * 10}px, ${py * 10}px)`,
                transition: "transform 0.35s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <div className="w-14 h-14 rounded-xl overflow-hidden flex-shrink-0 bg-surface-container-high flex items-center justify-center">
                <span className="material-symbols-outlined text-[28px] text-secondary-fixed-dim">smartphone</span>
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-1">
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-tertiary/20 text-tertiary-fixed text-label-sm">
                    Vérifié
                  </span>
                  <span className="text-body-sm text-secondary-fixed-dim">Plateau</span>
                </div>
                <h4 className="text-label-lg text-surface truncate mt-0.5">iPhone 14 Pro 128 Go</h4>
                <p className="text-headline-sm text-primary-container font-bold">420 000 FCFA</p>
              </div>
            </div>

            {/* Carte 2 */}
            <div
              className="rounded-2xl bg-surface-container-lowest/10 backdrop-blur-md p-3.5 shadow-lg flex items-center gap-3.5"
              style={{
                transform: `translateX(12px) rotate(1deg) translate(${px * -10}px, ${py * -10}px)`,
                transition: "transform 0.45s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <div className="w-14 h-14 rounded-xl overflow-hidden flex-shrink-0 bg-surface-container-high flex items-center justify-center">
                <span className="material-symbols-outlined text-[28px] text-secondary-fixed-dim">apparel</span>
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-1">
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-primary-container/20 text-primary-fixed text-label-sm">
                    Neuf
                  </span>
                  <span className="text-body-sm text-secondary-fixed-dim">Almadies</span>
                </div>
                <h4 className="text-label-lg text-surface truncate mt-0.5">Boubou Signature Dakar</h4>
                <p className="text-headline-sm text-primary-container font-bold">45 000 FCFA</p>
              </div>
            </div>
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
              <span className="material-symbols-outlined text-tertiary-fixed text-[18px]">verified_user</span>
              Paiement sécurisé
            </div>
            <div
              className="inline-flex items-center gap-2 bg-surface-container-lowest/8 px-3.5 py-2 rounded-full text-secondary-fixed-dim text-label-md w-fit"
              style={{
                transform: `translate(${px * -12}px, ${py * 12}px)`,
                transition: "transform 0.45s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <span className="material-symbols-outlined text-primary-container text-[18px]">star</span>
              Vendeurs certifiés
            </div>
            <div
              className="inline-flex items-center gap-2 bg-surface-container-lowest/8 px-3.5 py-2 rounded-full text-secondary-fixed-dim text-label-md w-fit"
              style={{
                transform: `translate(${px * 10}px, ${py * -10}px)`,
                transition: "transform 0.55s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
              }}
            >
              <span className="material-symbols-outlined text-secondary-fixed-dim text-[18px]">support_agent</span>
              Support 7j/7
            </div>
          </div>
        </aside>

        {/* ── Panneau droit ── */}
        <section className="relative w-full lg:w-7/12 bg-background p-8 md:p-12 lg:p-16 flex flex-col justify-between overflow-hidden">
          {/* Blobs animés derrière le formulaire */}
          <div
            className="absolute top-0 right-0 w-64 h-64 rounded-full bg-primary-fixed/30 blur-3xl pointer-events-none animate-bob"
            style={{ animationDuration: "7s" }}
          />
          <div
            className="absolute bottom-0 left-0 w-56 h-56 rounded-full bg-tertiary-fixed/20 blur-3xl pointer-events-none animate-bob"
            style={{ animationDuration: "10s", animationDelay: "2s" }}
          />
          <div
            className="absolute top-1/2 left-1/3 w-48 h-48 rounded-full bg-secondary-fixed/10 blur-2xl pointer-events-none animate-bob"
            style={{ animationDuration: "8s", animationDelay: "1s" }}
          />

          {/* En-tête */}
          <div className="relative z-10 flex items-center justify-between mb-8">
            <div className="flex items-center gap-2">
              <div className="rounded-[5px] overflow-hidden">
                <Image src="/R.png" alt="Rizen" width={28} height={28} className="h-7 w-auto" />
              </div>
              <span className="text-headline-sm text-on-secondary-fixed tracking-tight">Rizen</span>
            </div>
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 text-label-md text-secondary hover:text-primary-container transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">arrow_back</span>
              Retour au site
            </Link>
          </div>

          {/* Formulaire */}
          <div className="relative z-10 max-w-md w-full mx-auto flex-1 flex flex-col justify-center">
            <div className="mb-8">
              <h1 className="text-display-lg-mobile md:text-display-lg text-on-secondary-fixed tracking-tight flex items-center gap-3">
                Bon retour
                <span className="material-symbols-outlined text-primary-container" style={{ fontSize: "36px" }}>
                  waving_hand
                </span>
              </h1>
              <p className="text-body-lg text-secondary mt-1">
                Connectez-vous pour retrouver vos annonces et messages.
              </p>
            </div>

            {/* Bouton Google */}
            <button
              type="button"
              onClick={handleGoogle}
              className="w-full h-[52px] px-6 rounded-full bg-surface-container-lowest shadow-card hover:shadow-card-hover text-on-secondary-fixed text-body-lg flex items-center justify-center gap-3 transition-all hover:bg-surface-container-low"
            >
              <svg className="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05" />
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335" />
              </svg>
              <span>Continuer avec Google</span>
            </button>

            {/* Séparateur */}
            <div className="relative flex items-center justify-center my-6">
              <div className="w-full h-px bg-surface-container-highest" />
              <span className="absolute px-4 bg-background text-body-sm text-secondary">
                ou avec votre email
              </span>
            </div>

            {/* Formulaire email */}
            <form onSubmit={handleLogin} className="flex flex-col gap-5">
              {error && (
                <div className="bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-2xl flex items-center gap-2">
                  <span className="material-symbols-outlined text-[18px]">error</span>
                  {error}
                </div>
              )}

              {/* Email */}
              <div className="flex flex-col gap-1.5">
                <label className="text-label-lg text-on-surface" htmlFor="email">
                  Adresse email
                </label>
                <input
                  id="email"
                  type="email"
                  placeholder="exemple@gmail.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full h-[52px] px-4 rounded-2xl bg-surface-container-lowest text-on-surface text-body-md outline-none transition-all placeholder:text-secondary/60"
                  style={{ boxShadow: "0 4px 20px rgba(19, 27, 45, 0.05)" }}
                  onFocus={(e) => (e.currentTarget.style.boxShadow = "0 0 0 1.5px #FC7138, 0 4px 20px rgba(19, 27, 45, 0.08)")}
                  onBlur={(e) => (e.currentTarget.style.boxShadow = "0 4px 20px rgba(19, 27, 45, 0.05)")}
                />
              </div>

              {/* Mot de passe */}
              <div className="flex flex-col gap-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-label-lg text-on-surface" htmlFor="password">
                    Mot de passe
                  </label>
                  <Link
                    href="/auth/forgot-password"
                    className="text-label-md text-primary-container hover:underline"
                  >
                    Mot de passe oublié ?
                  </Link>
                </div>
                <div className="relative flex items-center">
                  <input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="w-full h-[52px] pl-4 pr-12 rounded-2xl bg-surface-container-lowest text-on-surface text-body-md outline-none transition-all placeholder:text-secondary/60"
                    style={{ boxShadow: "0 4px 20px rgba(19, 27, 45, 0.05)" }}
                    onFocus={(e) => (e.currentTarget.style.boxShadow = "0 0 0 1.5px #FC7138, 0 4px 20px rgba(19, 27, 45, 0.08)")}
                    onBlur={(e) => (e.currentTarget.style.boxShadow = "0 4px 20px rgba(19, 27, 45, 0.05)")}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3.5 p-1.5 text-secondary hover:text-on-surface flex items-center justify-center focus:outline-none"
                    aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"}
                  >
                    <span className="material-symbols-outlined text-[20px]">
                      {showPassword ? "visibility_off" : "visibility"}
                    </span>
                  </button>
                </div>
              </div>

              {/* Bouton submit */}
              <button
                type="submit"
                disabled={loading}
                className="w-full h-[52px] mt-2 rounded-full bg-primary-container hover:bg-primary text-surface text-label-lg tracking-wide flex items-center justify-center gap-2 transition-all hover:scale-[1.01] active:scale-[0.99] disabled:opacity-70 disabled:cursor-not-allowed"
                style={{ boxShadow: "0 8px 24px rgba(252, 113, 56, 0.28)" }}
              >
                {loading ? (
                  <>
                    <span className="material-symbols-outlined text-[20px] animate-spin">progress_activity</span>
                    Connexion...
                  </>
                ) : (
                  <>
                    Se connecter
                    <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                  </>
                )}
              </button>
            </form>

            <p className="text-body-md text-center text-secondary mt-8">
              Pas encore de compte ?{" "}
              <Link href="/auth/register" className="text-label-lg text-primary-container hover:underline ml-1">
                S&apos;inscrire
              </Link>
            </p>
          </div>

          {/* Footer */}
          <div className="relative z-10 pt-8 border-t border-surface-container-highest flex flex-col sm:flex-row items-center justify-between gap-4 text-secondary text-label-sm">
            <span className="whitespace-nowrap">© 2026 Rizen Marketplace</span>
            <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2">
              <Link href="/conditions-generales" className="hover:text-on-surface transition-colors whitespace-nowrap">Conditions Générales</Link>
              <Link href="/confidentialite" className="hover:text-on-surface transition-colors whitespace-nowrap">Confidentialité</Link>
              <span className="inline-flex items-center gap-1.5 text-tertiary whitespace-nowrap">
                <span className="w-2 h-2 rounded-full bg-tertiary inline-block" />
                Plateforme active
              </span>
            </div>
          </div>
        </section>

      </div>
    </div>
  );
}
