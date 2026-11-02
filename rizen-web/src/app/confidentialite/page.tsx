import Link from "next/link";
import Image from "next/image";
import BackButton from "@/components/ui/BackButton";

export const metadata = {
  title: "Politique de Confidentialité — Rizen",
  description: "Politique de Confidentialité et protection des données personnelles de Rizen Marketplace.",
};

const LAST_UPDATE = "1er janvier 2026";

export default function ConfidentialitePage() {
  return (
    <div className="min-h-screen bg-background text-on-surface">

      {/* En-tête */}
      <header className="sticky top-0 z-50 bg-background/95 backdrop-blur border-b border-surface-container-highest">
        <div className="max-w-4xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2 group">
            <div className="rounded-[10px] overflow-hidden">
              <Image src="/R.png" alt="Rizen" width={32} height={32} className="h-8 w-auto object-contain" />
            </div>
            <span className="text-headline-sm text-on-secondary-fixed tracking-tight">Rizen</span>
          </Link>
          <BackButton />
        </div>
      </header>

      {/* Corps */}
      <main className="max-w-4xl mx-auto px-6 py-12 md:py-16">

        {/* Titre */}
        <div className="mb-12">
          <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-tertiary-fixed/40 text-tertiary text-label-sm font-semibold mb-4">
            <span className="material-symbols-outlined text-[14px]">shield</span>
            Protection des données
          </span>
          <h1 className="text-display-lg-mobile md:text-display-lg font-bold text-on-secondary-fixed tracking-tight mb-3">
            Politique de Confidentialité
          </h1>
          <p className="text-body-lg text-secondary">
            Dernière mise à jour : <strong>{LAST_UPDATE}</strong>
          </p>
          <div className="mt-6 p-4 rounded-2xl bg-surface-container-low border-l-4 border-tertiary text-body-md text-secondary">
            Cette politique est établie conformément à la{" "}
            <strong>Loi n° 2008-12 du 25 janvier 2008</strong> sur la protection des données à caractère
            personnel au Sénégal et aux recommandations de la{" "}
            <strong>Commission de Protection des Données Personnelles (CDP)</strong>.
          </div>
        </div>

        <div className="space-y-10 text-body-md leading-relaxed">

          {/* 1 */}
          <Section number="1" title="Responsable du traitement">
            <p>
              Le responsable du traitement de vos données personnelles est :{" "}
              <strong>Rizen SAS</strong>, société enregistrée à Dakar, Sénégal.
            </p>
            <p className="mt-3">
              Contact délégué à la protection des données :{" "}
              <a href="https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com" target="_blank" rel="noopener noreferrer" className="text-primary-container hover:underline font-medium">
                rizen.marketplace@gmail.com
              </a>
            </p>
          </Section>

          {/* 2 */}
          <Section number="2" title="Données collectées">
            <p>Dans le cadre de l&apos;utilisation de la Plateforme, nous collectons les données suivantes :</p>
            <div className="mt-4 space-y-4">
              {[
                {
                  cat: "Données d'identification",
                  icon: "person",
                  items: ["Nom et prénom", "Adresse email", "Numéro de téléphone", "Ville / Adresse"],
                },
                {
                  cat: "Données d'utilisation",
                  icon: "analytics",
                  items: ["Historique des annonces publiées", "Messages échangés sur la plateforme", "Adresse IP et données de navigation"],
                },
                {
                  cat: "Données de transaction",
                  icon: "payments",
                  items: ["Annonces achetées ou vendues", "Évaluations et avis laissés"],
                },
              ].map((group) => (
                <div key={group.cat} className="p-4 rounded-2xl bg-surface-container-lowest shadow-card">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="material-symbols-outlined text-primary-container text-[18px]">{group.icon}</span>
                    <span className="text-label-lg text-on-surface font-semibold">{group.cat}</span>
                  </div>
                  <ul className="space-y-1 pl-2">
                    {group.items.map((item) => (
                      <li key={item} className="flex items-center gap-2 text-secondary">
                        <span className="w-1.5 h-1.5 rounded-full bg-primary-container shrink-0" />
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </Section>

          {/* 3 */}
          <Section number="3" title="Finalités du traitement">
            <p>Vos données sont traitées pour les finalités suivantes :</p>
            <ul className="mt-3 space-y-2 pl-5 list-disc">
              <li>Création et gestion de votre compte utilisateur ;</li>
              <li>Publication, gestion et modération des annonces ;</li>
              <li>Facilitation des mises en relation entre Vendeurs et Acheteurs ;</li>
              <li>Envoi de notifications relatives à votre activité sur la Plateforme ;</li>
              <li>Amélioration des services et personnalisation de l&apos;expérience utilisateur ;</li>
              <li>Respect de nos obligations légales et réglementaires ;</li>
              <li>Prévention des fraudes et sécurisation de la Plateforme.</li>
            </ul>
          </Section>

          {/* 4 */}
          <Section number="4" title="Base légale du traitement">
            <p>
              Conformément à la <strong>Loi n° 2008-12</strong>, le traitement de vos données repose sur :
            </p>
            <ul className="mt-3 space-y-2 pl-5 list-disc">
              <li><strong>Votre consentement</strong> lors de la création de votre compte ;</li>
              <li><strong>L&apos;exécution du contrat</strong> formé par l&apos;acceptation des CGU ;</li>
              <li><strong>Nos obligations légales</strong> en matière de lutte contre la fraude ;</li>
              <li><strong>Notre intérêt légitime</strong> à améliorer et sécuriser la Plateforme.</li>
            </ul>
          </Section>

          {/* 5 */}
          <Section number="5" title="Durée de conservation">
            <p>Vos données sont conservées pendant les durées suivantes :</p>
            <ul className="mt-3 space-y-2">
              {[
                ["Données de compte actif", "Durée de vie du compte"],
                ["Données de compte supprimé", "3 ans (obligations légales)"],
                ["Données de transaction", "10 ans (COCC, obligations comptables)"],
                ["Données de navigation", "13 mois maximum"],
              ].map(([type, durée]) => (
                <li key={type} className="flex items-center justify-between p-3 rounded-xl bg-surface-container-lowest border border-surface-container-highest">
                  <span className="text-on-surface font-medium">{type}</span>
                  <span className="text-label-md text-primary-container font-semibold">{durée}</span>
                </li>
              ))}
            </ul>
          </Section>

          {/* 6 */}
          <Section number="6" title="Vos droits">
            <p>
              Conformément à la <strong>Loi n° 2008-12</strong> et aux directives de la <strong>CDP</strong>,
              vous disposez des droits suivants sur vos données :
            </p>
            <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[
                { icon: "visibility", right: "Droit d'accès", desc: "Obtenir une copie de vos données." },
                { icon: "edit", right: "Droit de rectification", desc: "Corriger des données inexactes." },
                { icon: "delete", right: "Droit d'effacement", desc: "Demander la suppression de vos données." },
                { icon: "block", right: "Droit d'opposition", desc: "Vous opposer à certains traitements." },
                { icon: "download", right: "Droit à la portabilité", desc: "Récupérer vos données en format lisible." },
                { icon: "pause_circle", right: "Droit de limitation", desc: "Limiter le traitement de vos données." },
              ].map((item) => (
                <div key={item.right} className="flex gap-3 p-3 rounded-xl bg-surface-container-lowest shadow-card">
                  <span className="material-symbols-outlined text-tertiary text-[20px] shrink-0 mt-0.5">{item.icon}</span>
                  <div>
                    <p className="text-label-lg text-on-surface font-semibold">{item.right}</p>
                    <p className="text-body-sm text-secondary">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
            <p className="mt-4">
              Pour exercer ces droits, contactez-nous à{" "}
              <a href="https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com" target="_blank" rel="noopener noreferrer" className="text-primary-container hover:underline font-medium">
                rizen.marketplace@gmail.com
              </a>
              . Nous répondrons dans un délai de <strong>30 jours</strong>.
            </p>
          </Section>

          {/* 7 */}
          <Section number="7" title="Partage des données avec des tiers">
            <p>
              Rizen ne vend pas vos données personnelles. Vos données peuvent être partagées avec :
            </p>
            <ul className="mt-3 space-y-2 pl-5 list-disc">
              <li><strong>Supabase</strong> (hébergement et base de données, serveurs en Europe) ;</li>
              <li><strong>Prestataires de paiement</strong> (Wave, Orange Money) dans le cadre des transactions ;</li>
              <li><strong>Autorités compétentes</strong> en cas d&apos;obligation légale (CDP, tribunaux sénégalais).</li>
            </ul>
          </Section>

          {/* 8 */}
          <Section number="8" title="Sécurité des données">
            <p>
              Rizen met en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos
              données contre tout accès non autorisé, perte ou destruction, notamment :
            </p>
            <ul className="mt-3 space-y-1.5 pl-5 list-disc">
              <li>Chiffrement des données en transit (HTTPS/TLS) ;</li>
              <li>Authentification sécurisée via Supabase Auth ;</li>
              <li>Accès aux données restreint au personnel autorisé ;</li>
              <li>Surveillance et journalisation des accès.</li>
            </ul>
          </Section>

          {/* 9 */}
          <Section number="9" title="Cookies et traceurs">
            <p>
              La Plateforme utilise uniquement des cookies strictement nécessaires à son fonctionnement
              (authentification, préférences de session). Aucun cookie publicitaire ou de suivi tiers n&apos;est
              utilisé sans votre consentement explicite.
            </p>
          </Section>

          {/* 10 */}
          <Section number="10" title="Réclamation auprès de la CDP">
            <p>
              Si vous estimez que le traitement de vos données ne respecte pas la réglementation en vigueur,
              vous avez le droit d&apos;introduire une réclamation auprès de la{" "}
              <strong>Commission de Protection des Données Personnelles (CDP)</strong> du Sénégal :
            </p>
            <div className="mt-4 p-4 rounded-2xl bg-surface-container-low flex flex-col gap-1 text-body-md">
              <p><strong className="text-on-surface">CDP Sénégal</strong></p>
              <p className="text-secondary">Dakar, Sénégal</p>
              <a href="https://cdp.sn" target="_blank" rel="noopener noreferrer" className="text-primary-container hover:underline font-medium">
                www.cdp.sn
              </a>
            </div>
          </Section>

          {/* 11 */}
          <Section number="11" title="Modifications de la politique">
            <p>
              Rizen se réserve le droit de modifier la présente politique. Toute modification substantielle
              vous sera notifiée par email ou par notification sur la Plateforme au moins{" "}
              <strong>15 jours avant</strong> son entrée en vigueur.
            </p>
          </Section>

        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-surface-container-highest mt-16 py-8">
        <div className="max-w-4xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-label-sm text-secondary">
          <span>© 2026 Rizen Marketplace</span>
          <div className="flex items-center gap-4">
            <Link href="/conditions-generales" className="hover:text-on-surface transition-colors">CGU</Link>
            <span>•</span>
            <Link href="/confidentialite" className="text-on-surface font-semibold">Confidentialité</Link>
          </div>
        </div>
      </footer>

    </div>
  );
}

// ── Composant section ────────────────────────────────────────────────
function Section({ number, title, children }: { number: string; title: string; children: React.ReactNode }) {
  return (
    <section>
      <div className="flex items-center gap-3 mb-4">
        <span className="flex-shrink-0 w-8 h-8 rounded-full bg-tertiary-fixed/40 text-tertiary text-label-md font-bold flex items-center justify-center">
          {number}
        </span>
        <h2 className="text-headline-sm text-on-secondary-fixed">{title}</h2>
      </div>
      <div className="pl-11 text-secondary">{children}</div>
    </section>
  );
}
