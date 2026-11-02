import Link from "next/link";
import Image from "next/image";
import BackButton from "@/components/ui/BackButton";

export const metadata = {
  title: "Conseils de sécurité — Rizen",
  description: "Guide pratique pour acheter et vendre en toute sécurité sur Rizen Marketplace.",
};

const WHATSAPP = "https://wa.me/221787571756";
const GMAIL = "https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com";

const TIPS = [
  {
    icon: "location_on",
    color: "bg-primary-fixed/40 text-primary-container",
    title: "Choisissez un lieu public et animé",
    tips: [
      "Privilégiez les centres commerciaux, marchés, cafés ou banques.",
      "Évitez les domiciles privés, surtout pour une première rencontre.",
      "Informez toujours un proche de l'heure et du lieu du rendez-vous.",
      "Ne vous déplacez jamais seul(e) pour un article de grande valeur.",
    ],
  },
  {
    icon: "payments",
    color: "bg-tertiary-fixed/40 text-tertiary",
    title: "Sécurisez vos paiements",
    tips: [
      "Préférez le paiement en main propre à la réception de l'article.",
      "Si vous utilisez Wave ou Orange Money, confirmez la réception avant de valider.",
      "Ne versez jamais d'acompte avant d'avoir vu l'article en vrai.",
      "Méfiez-vous des vendeurs qui demandent un virement avant la rencontre.",
    ],
  },
  {
    icon: "verified_user",
    color: "bg-secondary-fixed text-on-secondary-fixed",
    title: "Vérifiez l'article avant d'acheter",
    tips: [
      "Testez le produit sur place : allumage, fonctionnement, état général.",
      "Pour l'électronique, vérifiez le numéro IMEI ou le numéro de série.",
      "Pour les véhicules, demandez le titre de propriété et vérifiez le numéro de châssis.",
      "N'acceptez pas un emballage scellé que vous ne pouvez pas ouvrir avant paiement.",
    ],
  },
  {
    icon: "manage_accounts",
    color: "bg-primary-fixed/40 text-primary-container",
    title: "Protégez votre compte",
    tips: [
      "Utilisez un mot de passe fort et unique pour votre compte Rizen.",
      "Ne partagez jamais vos identifiants de connexion.",
      "Activez la connexion Google pour une authentification plus sécurisée.",
      "Déconnectez-vous si vous utilisez un appareil partagé.",
    ],
  },
  {
    icon: "sms",
    color: "bg-tertiary-fixed/40 text-tertiary",
    title: "Communiquez avec prudence",
    tips: [
      "Gardez vos échanges sur la messagerie Rizen tant que possible.",
      "Ne communiquez votre numéro personnel qu'au moment de finaliser la transaction.",
      "Méfiez-vous des messages urgents ou des offres trop belles pour être vraies.",
      "Un vendeur ou acheteur légitime ne vous demandera jamais votre mot de passe.",
    ],
  },
  {
    icon: "warning",
    color: "bg-error/10 text-error",
    title: "Reconnaître une arnaque",
    tips: [
      "Prix anormalement bas par rapport au marché (ex: iPhone dernier modèle à 50 000 FCFA).",
      "Vendeur qui prétend être à l'étranger et propose l'envoi par colis.",
      "Demande de paiement via recharge de crédit téléphonique.",
      "Profil créé récemment, sans photo ni avis vérifiés.",
    ],
  },
];

export default function ConseilsSecuritePage() {
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
          <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-tertiary/10 text-tertiary text-label-sm font-semibold mb-4">
            <span className="material-symbols-outlined text-[14px]">security</span>
            Guide de sécurité
          </span>
          <h1 className="text-display-lg-mobile md:text-display-lg font-bold text-on-secondary-fixed tracking-tight mb-3">
            Conseils de sécurité
          </h1>
          <p className="text-body-lg text-secondary max-w-2xl">
            Acheter et vendre en ligne comporte des risques. Voici les bonnes pratiques pour protéger votre argent et votre sécurité sur Rizen.
          </p>
        </div>

        {/* Alerte principale */}
        <div className="flex gap-4 p-4 sm:p-5 rounded-2xl bg-error-container text-on-error-container">
          <span className="material-symbols-outlined text-[24px] shrink-0 mt-0.5">campaign</span>
          <div>
            <p className="text-label-lg font-bold mb-1">Règle d&apos;or</p>
            <p className="text-body-md">
              Rizen ne vous demandera <strong>jamais</strong> de payer pour publier une annonce, de communiquer votre mot de passe, ni de transférer de l&apos;argent avant d&apos;avoir vu l&apos;article en personne.
            </p>
          </div>
        </div>

        {/* Conseils par thème */}
        <div className="space-y-6">
          {TIPS.map((section) => (
            <div key={section.title} className="rounded-3xl bg-surface-container-lowest shadow-card overflow-hidden">
              <div className="flex items-center gap-3 p-4 sm:p-5 border-b border-surface-container-highest">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${section.color}`}>
                  <span className="material-symbols-outlined text-[20px]">{section.icon}</span>
                </div>
                <h2 className="text-headline-sm text-on-secondary-fixed">{section.title}</h2>
              </div>
              <ul className="p-4 sm:p-5 space-y-3">
                {section.tips.map((tip) => (
                  <li key={tip} className="flex items-start gap-3 text-body-md text-secondary">
                    <span className="material-symbols-outlined text-tertiary text-[18px] shrink-0 mt-0.5">check_circle</span>
                    {tip}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Que faire en cas de problème */}
        <div className="rounded-3xl bg-on-secondary-fixed p-6 sm:p-8 text-surface-container-lowest">
          <div className="flex items-center gap-3 mb-5">
            <span className="material-symbols-outlined text-primary-container text-[24px]">report</span>
            <h2 className="text-headline-sm text-surface-container-lowest">Vous êtes victime d&apos;une arnaque ?</h2>
          </div>
          <ol className="space-y-3 text-body-md text-secondary-fixed-dim list-none">
            {[
              "Cessez immédiatement tout contact avec la personne concernée.",
              "Signalez l'annonce ou le profil via le bouton « Signaler » sur la plateforme.",
              "Conservez toutes les preuves : captures d'écran, messages, numéros de transaction.",
              "Contactez notre équipe via WhatsApp ou email pour un traitement prioritaire.",
              "En cas d'escroquerie avérée, portez plainte auprès de la brigade cybercriminalité de la DIC (Direction des Investigations Criminelles) du Sénégal.",
            ].map((step, i) => (
              <li key={i} className="flex items-start gap-3">
                <span className="flex-shrink-0 w-6 h-6 rounded-full bg-primary-container/20 text-primary-container text-label-sm font-bold flex items-center justify-center">
                  {i + 1}
                </span>
                {step}
              </li>
            ))}
          </ol>
          <div className="flex flex-wrap gap-3 mt-6">
            <a
              href={WHATSAPP}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 h-[44px] px-5 rounded-full bg-tertiary text-white text-label-lg hover:opacity-90 transition-all"
            >
              <span className="material-symbols-outlined text-[18px]">chat</span>
              WhatsApp
            </a>
            <a
              href={GMAIL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 h-[44px] px-5 rounded-full bg-surface-container-lowest/10 text-surface-container-lowest text-label-lg hover:bg-surface-container-lowest/20 transition-all"
            >
              <span className="material-symbols-outlined text-[18px]">mail</span>
              Envoyer un email
            </a>
          </div>
        </div>

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
