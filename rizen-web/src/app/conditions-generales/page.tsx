import Link from "next/link";
import Image from "next/image";
import BackButton from "@/components/ui/BackButton";

export const metadata = {
  title: "Conditions Générales d'Utilisation — Rizen",
  description: "Conditions Générales d'Utilisation de la plateforme Rizen Marketplace.",
};

const LAST_UPDATE = "1er janvier 2026";

export default function ConditionsGeneralesPage() {
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
          <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary-fixed/40 text-primary-container text-label-sm font-semibold mb-4">
            <span className="material-symbols-outlined text-[14px]">gavel</span>
            Document légal
          </span>
          <h1 className="text-display-lg-mobile md:text-display-lg font-bold text-on-secondary-fixed tracking-tight mb-3">
            Conditions Générales d&apos;Utilisation
          </h1>
          <p className="text-body-lg text-secondary">
            Dernière mise à jour : <strong>{LAST_UPDATE}</strong>
          </p>
          <div className="mt-6 p-4 rounded-2xl bg-surface-container-low border-l-4 border-primary-container text-body-md text-secondary">
            Ces CGU sont régies par le droit sénégalais, notamment la{" "}
            <strong>Loi n° 2008-08 du 25 janvier 2008</strong> sur les transactions électroniques et le{" "}
            <strong>Code des Obligations Civiles et Commerciales (COCC)</strong>.
          </div>
        </div>

        <div className="space-y-10 text-body-md leading-relaxed">

          {/* 1 */}
          <Section number="1" title="Objet et champ d'application">
            <p>
              Les présentes Conditions Générales d&apos;Utilisation (ci-après « CGU ») régissent l&apos;accès et
              l&apos;utilisation de la plateforme <strong>Rizen Marketplace</strong> (ci-après « la Plateforme »),
              accessible à l&apos;adresse web et via l&apos;application mobile éponyme, éditée par{" "}
              <strong>Rizen SAS</strong>, société enregistrée à Dakar, Sénégal.
            </p>
            <p className="mt-3">
              Toute utilisation de la Plateforme implique l&apos;acceptation pleine et entière des présentes CGU.
              L&apos;utilisateur qui n&apos;accepte pas ces conditions doit cesser immédiatement d&apos;utiliser
              la Plateforme.
            </p>
          </Section>

          {/* 2 */}
          <Section number="2" title="Définitions">
            <ul className="space-y-2 list-none">
              {[
                ["Plateforme", "Le site web et l'application mobile Rizen Marketplace."],
                ["Utilisateur", "Toute personne physique ou morale ayant créé un compte sur la Plateforme."],
                ["Vendeur", "Tout utilisateur publiant une ou plusieurs annonces de vente."],
                ["Acheteur", "Tout utilisateur souhaitant acquérir un bien proposé sur la Plateforme."],
                ["Annonce", "Offre de vente publiée par un Vendeur, décrivant un bien et son prix."],
                ["Transaction", "L'ensemble du processus d'achat/vente entre un Vendeur et un Acheteur."],
              ].map(([term, def]) => (
                <li key={term} className="flex gap-3">
                  <span className="shrink-0 text-primary-container font-bold">—</span>
                  <span><strong className="text-on-surface">{term} :</strong> {def}</span>
                </li>
              ))}
            </ul>
          </Section>

          {/* 3 */}
          <Section number="3" title="Inscription et compte utilisateur">
            <p>
              L&apos;accès aux fonctionnalités complètes de la Plateforme est subordonné à la création d&apos;un
              compte. L&apos;utilisateur doit être âgé d&apos;au moins <strong>18 ans</strong> ou disposer d&apos;une
              autorisation parentale conforme au droit sénégalais.
            </p>
            <p className="mt-3">
              L&apos;utilisateur s&apos;engage à fournir des informations exactes, complètes et à les maintenir
              à jour. Tout compte créé avec des informations frauduleuses pourra être suspendu ou supprimé sans
              préavis.
            </p>
            <p className="mt-3">
              L&apos;utilisateur est seul responsable de la confidentialité de ses identifiants de connexion et
              de toutes les actions effectuées depuis son compte.
            </p>
          </Section>

          {/* 4 */}
          <Section number="4" title="Publication d'annonces">
            <p>
              Le Vendeur s&apos;engage à publier des annonces sincères, précises et complètes. Sont notamment
              interdits :
            </p>
            <ul className="mt-3 space-y-1.5 pl-5 list-disc text-secondary">
              <li>Les annonces de biens volés, contrefaits ou dont la vente est réglementée ou prohibée au Sénégal ;</li>
              <li>Les annonces comportant des informations mensongères ou trompeuses ;</li>
              <li>Les doublons d&apos;annonces pour le même bien ;</li>
              <li>Les annonces à caractère discriminatoire, offensant ou contraire aux bonnes mœurs ;</li>
              <li>Les annonces de vente d&apos;armes, de substances illicites ou de données personnelles.</li>
            </ul>
            <p className="mt-3">
              Rizen se réserve le droit de supprimer toute annonce ne respectant pas ces règles, sans préavis
              ni indemnisation.
            </p>
          </Section>

          {/* 5 */}
          <Section number="5" title="Transactions et paiements">
            <p>
              Rizen est une plateforme de mise en relation. Elle n&apos;est pas partie aux transactions conclues
              entre Vendeurs et Acheteurs. Les paiements peuvent s&apos;effectuer directement en espèces lors
              d&apos;une remise en main propre, ou via des services de paiement mobile tels que{" "}
              <strong>Wave</strong> ou <strong>Orange Money</strong>.
            </p>
            <p className="mt-3">
              Rizen recommande vivement de procéder aux remises en main propre dans des lieux publics et
              sécurisés. Toute transaction effectuée reste sous la responsabilité exclusive du Vendeur et de
              l&apos;Acheteur, conformément aux dispositions du <strong>COCC</strong>.
            </p>
          </Section>

          {/* 6 */}
          <Section number="6" title="Responsabilités">
            <p>
              Rizen s&apos;efforce d&apos;assurer la disponibilité de la Plateforme mais ne peut garantir un
              accès ininterrompu. En aucun cas Rizen ne pourra être tenu responsable :
            </p>
            <ul className="mt-3 space-y-1.5 pl-5 list-disc text-secondary">
              <li>Des dommages résultant d&apos;une fraude entre utilisateurs ;</li>
              <li>De l&apos;inexactitude des informations fournies par les utilisateurs ;</li>
              <li>Des pertes de données liées à des cas de force majeure ;</li>
              <li>Des litiges relatifs à la qualité ou à la conformité des biens vendus.</li>
            </ul>
          </Section>

          {/* 7 */}
          <Section number="7" title="Propriété intellectuelle">
            <p>
              La marque <strong>Rizen</strong>, le logo, le design et l&apos;ensemble des contenus de la
              Plateforme sont la propriété exclusive de Rizen SAS et sont protégés par les dispositions de la{" "}
              <strong>Loi n° 2008-09 du 25 janvier 2008</strong> sur le droit d&apos;auteur et les droits
              voisins au Sénégal. Toute reproduction, représentation ou exploitation non autorisée est
              strictement interdite.
            </p>
          </Section>

          {/* 8 */}
          <Section number="8" title="Résiliation du compte">
            <p>
              L&apos;utilisateur peut supprimer son compte à tout moment depuis les paramètres de son profil.
              Rizen se réserve le droit de suspendre ou supprimer tout compte en cas de violation des présentes
              CGU, sans préavis et sans engagement de sa responsabilité.
            </p>
          </Section>

          {/* 9 */}
          <Section number="9" title="Modification des CGU">
            <p>
              Rizen se réserve le droit de modifier les présentes CGU à tout moment. Les utilisateurs seront
              informés de toute modification substantielle par notification sur la Plateforme ou par email.
              La poursuite de l&apos;utilisation de la Plateforme après notification vaut acceptation des
              nouvelles CGU.
            </p>
          </Section>

          {/* 10 */}
          <Section number="10" title="Droit applicable et juridiction compétente">
            <p>
              Les présentes CGU sont soumises au <strong>droit sénégalais</strong>. En cas de litige relatif
              à l&apos;interprétation ou à l&apos;exécution des présentes, les parties s&apos;engagent à
              rechercher une solution amiable. À défaut, tout litige sera soumis à la compétence exclusive
              des <strong>Tribunaux de Dakar</strong>, Sénégal.
            </p>
            <p className="mt-3">
              Pour toute question relative aux présentes CGU, vous pouvez nous contacter à :{" "}
              <a href="https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com" target="_blank" rel="noopener noreferrer" className="text-primary-container hover:underline font-medium">
                rizen.marketplace@gmail.com
              </a>
            </p>
          </Section>

        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-surface-container-highest mt-16 py-8">
        <div className="max-w-4xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-label-sm text-secondary">
          <span>© 2026 Rizen Marketplace</span>
          <div className="flex items-center gap-4">
            <Link href="/conditions-generales" className="text-on-surface font-semibold">CGU</Link>
            <span>•</span>
            <Link href="/confidentialite" className="hover:text-on-surface transition-colors">Confidentialité</Link>
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
        <span className="flex-shrink-0 w-8 h-8 rounded-full bg-primary-fixed/40 text-primary-container text-label-md font-bold flex items-center justify-center">
          {number}
        </span>
        <h2 className="text-headline-sm text-on-secondary-fixed">{title}</h2>
      </div>
      <div className="pl-11 text-secondary">{children}</div>
    </section>
  );
}
