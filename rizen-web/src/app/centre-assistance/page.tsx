"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";
import BackButton from "@/components/ui/BackButton";

const WHATSAPP = "https://wa.me/221787571756";
const GMAIL_DIRECT = "https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com";

const TOPICS = [
  { value: "Problème de compte", label: "Problème de compte" },
  { value: "Problème avec une annonce", label: "Problème avec une annonce" },
  { value: "Problème de transaction", label: "Problème de transaction" },
  { value: "Signaler une arnaque", label: "Signaler une arnaque" },
  { value: "Problème technique", label: "Problème technique" },
  { value: "Autre demande", label: "Autre demande" },
];

const FAQS = [
  {
    q: "Comment supprimer mon compte ?",
    a: "Rendez-vous dans Paramètres > Mon compte > Supprimer mon compte. La suppression est définitive et entraîne l'effacement de toutes vos données.",
  },
  {
    q: "Mon annonce a été supprimée, pourquoi ?",
    a: "Votre annonce ne respectait probablement pas nos règles de diffusion. Consultez la page Règles de diffusion pour en savoir plus, puis republiez en corrigeant le problème.",
  },
  {
    q: "Je n'arrive pas à me connecter avec Google.",
    a: "Vérifiez que les cookies sont activés dans votre navigateur. Si le problème persiste, essayez en mode navigation normale (pas en privé) ou contactez-nous.",
  },
  {
    q: "Comment signaler un vendeur suspect ?",
    a: "Sur l'annonce concernée, appuyez sur le bouton « Signaler ». Notre équipe examine chaque signalement sous 24 h.",
  },
];

type Status = "idle" | "sending" | "sent" | "error";

export default function CentreAssistancePage() {
  const [topic, setTopic] = useState("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("sending");
    try {
      const res = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email, topic, message }),
      });
      if (!res.ok) throw new Error();
      setStatus("sent");
      setTopic("");
      setName("");
      setEmail("");
      setMessage("");
    } catch {
      setStatus("error");
    }
  }

  return (
    <div className="min-h-screen bg-background text-on-surface">

      {/* En-tête */}
      <header className="sticky top-0 z-50 bg-background/95 backdrop-blur border-b border-surface-container-highest">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <div className="rounded-[10px] overflow-hidden">
              <Image src="/R.png" alt="Rizen" width={32} height={32} className="h-8 w-auto object-contain" />
            </div>
            <span className="text-headline-sm text-on-secondary-fixed tracking-tight">Rizen</span>
          </Link>
          <BackButton />
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 sm:px-6 py-10 md:py-16 space-y-12">

        {/* Titre */}
        <div>
          <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary-fixed/40 text-primary-container text-label-sm font-semibold mb-4">
            <span className="material-symbols-outlined text-[14px]">support_agent</span>
            Support Rizen
          </span>
          <h1 className="text-display-lg-mobile md:text-display-lg font-bold text-on-secondary-fixed tracking-tight mb-3">
            Centre d&apos;assistance
          </h1>
          <p className="text-body-lg text-secondary max-w-2xl">
            Besoin d&apos;aide ? Remplissez le formulaire ci-dessous ou contactez-nous directement sur WhatsApp.
          </p>
        </div>

        {/* Canaux rapides */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <a
            href={WHATSAPP}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-4 p-4 rounded-2xl bg-tertiary/10 hover:bg-tertiary/20 transition-colors group"
          >
            <div className="w-12 h-12 rounded-full bg-tertiary/20 flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-tertiary text-[24px]">chat</span>
            </div>
            <div>
              <p className="text-label-lg text-on-secondary-fixed font-semibold">WhatsApp</p>
              <p className="text-body-sm text-secondary">Réponse en moins d&apos;1 h</p>
            </div>
            <span className="material-symbols-outlined text-secondary text-[20px] ml-auto group-hover:translate-x-1 transition-transform">arrow_forward</span>
          </a>
          <a
            href={GMAIL_DIRECT}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-4 p-4 rounded-2xl bg-primary-fixed/20 hover:bg-primary-fixed/30 transition-colors group"
          >
            <div className="w-12 h-12 rounded-full bg-primary-container/20 flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-primary-container text-[24px]">mail</span>
            </div>
            <div>
              <p className="text-label-lg text-on-secondary-fixed font-semibold">Email direct</p>
              <p className="text-body-sm text-secondary">Ouvre Gmail dans un nouvel onglet</p>
            </div>
            <span className="material-symbols-outlined text-secondary text-[20px] ml-auto group-hover:translate-x-1 transition-transform">arrow_forward</span>
          </a>
        </div>

        {/* Formulaire de contact */}
        <div className="rounded-3xl bg-surface-container-lowest shadow-card overflow-hidden">
          <div className="p-5 border-b border-surface-container-highest">
            <h2 className="text-headline-sm text-on-secondary-fixed">Envoyer un message</h2>
            <p className="text-body-sm text-secondary mt-1">
              Votre message sera envoyé directement à l&apos;équipe Rizen.
            </p>
          </div>

          {status === "sent" ? (
            <div className="p-8 flex flex-col items-center text-center gap-4">
              <div className="w-16 h-16 rounded-full bg-tertiary/10 flex items-center justify-center">
                <span className="material-symbols-outlined text-tertiary text-[36px]">check_circle</span>
              </div>
              <p className="text-headline-sm text-on-secondary-fixed">Message envoyé !</p>
              <p className="text-body-md text-secondary max-w-sm">
                Nous avons bien reçu votre message. Notre équipe vous répondra à <strong>{email || "votre adresse"}</strong> dans les plus brefs délais.
              </p>
              <button
                onClick={() => setStatus("idle")}
                className="mt-2 inline-flex items-center gap-2 h-[44px] px-6 rounded-full bg-surface-container-low text-on-surface text-label-lg hover:bg-surface-container-highest transition-colors"
              >
                Envoyer un autre message
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="p-5 space-y-4">

              {/* Sujet */}
              <div>
                <label className="text-label-md text-on-surface mb-1.5 block">
                  Sujet <span className="text-error">*</span>
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[20px] pointer-events-none">help</span>
                  <select
                    required
                    value={topic}
                    onChange={(e) => setTopic(e.target.value)}
                    className="w-full h-[48px] pl-10 pr-10 rounded-xl bg-surface-container-low border border-surface-container-highest text-on-surface text-body-md appearance-none focus:outline-none focus:border-primary-container transition-colors"
                  >
                    <option value="">Sélectionnez un sujet</option>
                    {TOPICS.map((t) => (
                      <option key={t.value} value={t.value}>{t.label}</option>
                    ))}
                  </select>
                  <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-secondary text-[20px] pointer-events-none">expand_more</span>
                </div>
              </div>

              {/* Nom */}
              <div>
                <label className="text-label-md text-on-surface mb-1.5 block">
                  Votre nom <span className="text-error">*</span>
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[20px] pointer-events-none">person</span>
                  <input
                    required
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Ex : Amadou Diallo"
                    className="w-full h-[48px] pl-10 pr-4 rounded-xl bg-surface-container-low border border-surface-container-highest text-on-surface text-body-md placeholder:text-secondary focus:outline-none focus:border-primary-container transition-colors"
                  />
                </div>
              </div>

              {/* Email de contact */}
              <div>
                <label className="text-label-md text-on-surface mb-1.5 block">
                  Votre email <span className="text-error">*</span>
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[20px] pointer-events-none">mail</span>
                  <input
                    required
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="votre@email.com"
                    className="w-full h-[48px] pl-10 pr-4 rounded-xl bg-surface-container-low border border-surface-container-highest text-on-surface text-body-md placeholder:text-secondary focus:outline-none focus:border-primary-container transition-colors"
                  />
                </div>
              </div>

              {/* Message */}
              <div>
                <label className="text-label-md text-on-surface mb-1.5 block">
                  Votre message <span className="text-error">*</span>
                </label>
                <textarea
                  required
                  rows={5}
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Décrivez votre problème en détail..."
                  className="w-full p-3.5 rounded-xl bg-surface-container-low border border-surface-container-highest text-on-surface text-body-md placeholder:text-secondary focus:outline-none focus:border-primary-container transition-colors resize-none"
                />
              </div>

              {status === "error" && (
                <p className="flex items-center gap-2 text-error text-body-sm">
                  <span className="material-symbols-outlined text-[18px]">error</span>
                  Envoi échoué. Réessayez ou contactez-nous sur WhatsApp.
                </p>
              )}

              <button
                type="submit"
                disabled={status === "sending"}
                className="w-full h-[52px] rounded-full bg-on-secondary-fixed text-surface-container-lowest text-label-lg font-semibold flex items-center justify-center gap-2 hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-60"
              >
                {status === "sending" ? (
                  <>
                    <span className="material-symbols-outlined text-[20px] animate-spin">progress_activity</span>
                    Envoi en cours…
                  </>
                ) : (
                  <>
                    <span className="material-symbols-outlined text-[20px]">send</span>
                    Envoyer
                  </>
                )}
              </button>
            </form>
          )}
        </div>

        {/* FAQ */}
        <div>
          <h2 className="text-headline-md text-on-secondary-fixed mb-4">Questions fréquentes</h2>
          <div className="space-y-2">
            {FAQS.map((faq, i) => (
              <div key={i} className="rounded-2xl bg-surface-container-lowest shadow-card overflow-hidden">
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full flex items-center justify-between gap-3 p-4 text-left hover:bg-surface-container-low transition-colors"
                >
                  <span className="text-label-lg text-on-secondary-fixed">{faq.q}</span>
                  <span className={`material-symbols-outlined text-secondary text-[20px] shrink-0 transition-transform duration-200 ${openFaq === i ? "rotate-180" : ""}`}>
                    expand_more
                  </span>
                </button>
                {openFaq === i && (
                  <div className="px-4 pb-4 text-body-md text-secondary border-t border-surface-container-highest pt-3">
                    {faq.a}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Lien conseils sécurité */}
        <Link
          href="/conseils-securite"
          className="flex items-center gap-4 p-5 rounded-2xl bg-tertiary-fixed/20 hover:bg-tertiary-fixed/30 transition-colors group"
        >
          <div className="w-12 h-12 rounded-full bg-tertiary/10 flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-tertiary text-[24px]">security</span>
          </div>
          <div>
            <p className="text-label-lg text-on-secondary-fixed font-semibold">Conseils de sécurité</p>
            <p className="text-body-sm text-secondary">Évitez les arnaques avec nos bonnes pratiques.</p>
          </div>
          <span className="material-symbols-outlined text-secondary text-[20px] ml-auto group-hover:translate-x-1 transition-transform">arrow_forward</span>
        </Link>

      </main>

      {/* Footer */}
      <footer className="border-t border-surface-container-highest mt-8 py-8">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-label-sm text-secondary">
          <span>© 2026 Rizen Marketplace</span>
          <div className="flex flex-wrap justify-center items-center gap-4">
            <Link href="/conditions-generales" className="hover:text-on-surface transition-colors">CGU</Link>
            <span>•</span>
            <Link href="/confidentialite" className="hover:text-on-surface transition-colors">Confidentialité</Link>
            <span>•</span>
            <Link href="/regles-de-diffusion" className="hover:text-on-surface transition-colors">Règles de diffusion</Link>
          </div>
        </div>
      </footer>

    </div>
  );
}
