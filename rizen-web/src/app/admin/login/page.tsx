"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function AdminLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPwd, setShowPwd] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");

    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password });

    if (authError || !data.user) {
      setError("Identifiants incorrects.");
      setLoading(false);
      return;
    }

    // Vérifier le rôle superadmin
    const { data: profil } = await supabase
      .from("profils")
      .select("role")
      .eq("id", data.user.id)
      .maybeSingle();

    if (profil?.role !== "superadmin") {
      await supabase.auth.signOut();
      setError("Accès refusé. Vous n'avez pas les droits administrateur.");
      setLoading(false);
      return;
    }

    router.replace("/admin/dashboard");
  }

  return (
    <div className="min-h-screen bg-on-secondary-fixed flex items-center justify-center p-4">
      <div className="w-full max-w-md">

        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="rounded-[10px] overflow-hidden mb-4">
            <Image src="/Rizen.png" alt="Rizen" width={120} height={40} className="h-10 w-auto object-contain" priority />
          </div>
          <span className="text-label-md text-secondary-fixed-dim uppercase tracking-widest">Admin Console</span>
        </div>

        {/* Card */}
        <div className="bg-surface-container-lowest rounded-3xl shadow-2xl p-8">
          <div className="mb-6">
            <h1 className="text-headline-md text-on-secondary-fixed font-bold mb-1">Accès sécurisé</h1>
            <p className="text-body-sm text-secondary">Portail réservé aux administrateurs Rizen.</p>
          </div>

          {error && (
            <div className="flex items-center gap-2 bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-2xl mb-4">
              <span className="material-symbols-outlined text-[18px]">error</span>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="text-label-md text-on-surface mb-1.5 block">Adresse email</label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[20px] pointer-events-none">mail</span>
                <input
                  required
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@rizen.sn"
                  className="w-full h-[52px] pl-10 pr-4 rounded-2xl bg-surface-container-low border border-surface-container-highest text-on-surface text-body-md placeholder:text-secondary outline-none focus:border-primary-container transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="text-label-md text-on-surface mb-1.5 block">Mot de passe</label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[20px] pointer-events-none">lock</span>
                <input
                  required
                  type={showPwd ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full h-[52px] pl-10 pr-12 rounded-2xl bg-surface-container-low border border-surface-container-highest text-on-surface text-body-md placeholder:text-secondary outline-none focus:border-primary-container transition-colors"
                />
                <button type="button" onClick={() => setShowPwd(!showPwd)} className="absolute right-3 top-1/2 -translate-y-1/2 text-secondary hover:text-on-surface transition-colors">
                  <span className="material-symbols-outlined text-[20px]">{showPwd ? "visibility_off" : "visibility"}</span>
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full h-[52px] rounded-full bg-primary-container text-white text-label-lg font-semibold flex items-center justify-center gap-2 hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-60 mt-2"
            >
              {loading ? (
                <><span className="material-symbols-outlined text-[20px] animate-spin">progress_activity</span>Connexion…</>
              ) : (
                <><span className="material-symbols-outlined text-[20px]">admin_panel_settings</span>Accéder à la console</>
              )}
            </button>
          </form>
        </div>

        <p className="text-center text-label-sm text-secondary-fixed-dim mt-6">
          <Link href="/" className="hover:text-on-secondary transition-colors inline-flex items-center gap-1">
            <span className="material-symbols-outlined text-[14px]">arrow_back</span>
            Retour au site
          </Link>
        </p>

      </div>
    </div>
  );
}
