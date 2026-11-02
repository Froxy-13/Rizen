import Link from "next/link";
import Image from "next/image";
import BackButton from "@/components/ui/BackButton";

export const metadata = {
  title: "Règles de diffusion — Rizen",
  description: "Ce que vous pouvez et ne pouvez pas publier sur Rizen Marketplace.",
};

const WHATSAPP = "https://wa.me/221787571756";

const ALLOWED = [
  { icon: "smartphone", label: "Téléphones & électronique (en état de fonctionnement)" },
  { icon: "apparel", label: "Vêtements, chaussures & accessoires de mode" },
  { icon: "chair", label: "Meubles & articles de décoration" },
  { icon: "two_wheeler", label: "Véhicules, motos & vélos (avec titre de propriété)" },
  { icon: "menu_book", label: "Livres, fournitures scolaires & matériel pédagogique" },
  { icon: "fitness_center", label: "Équipements sportifs & loisirs" },
  { icon: "spa", label: "Cosmétiques & produits de beauté (non ouverts)" },
  { icon: "construction", label: "Outillage & matériel de bricolage" },
  { icon: "child_care", label: "Articles pour bébé & enfant" },
  { icon: "storefront", label: "Produits artisanaux locaux (wax, bijoux, sculpture...)" },
];

const FORBIDDEN = [
  { icon: "dangerous", label: "Armes, munitions et tout matériel d'armement" },
  { icon: "medication", label: "Médicaments, substances contrôlées et drogues" },
  { icon: "no_photography", label: "Contrefaçons, copies piratées et faux documents" },
  { icon: "block", label: "Animaux sauvages protégés ou espèces menacées" },
  { icon: "credit_card_off", label: "Données personnelles, comptes bancaires ou cartes SIM" },
  { icon: "money_off", label: "Schémas de vente pyramidale ou offres de prêt entre particuliers" },
  { icon: "no_adult_content", label: "Contenu à caractère sexuel explicite ou pornographique" },
  { icon: "policy", label: "Articles volés ou dont l'origine légale ne peut être prouvée" },
  { icon: "factory", label: "Matières dangereuses : explosifs, produits chimiques non autorisés" },
  { icon: "ballot", label: "Biens faisant l'objet d'un embargo ou d'une saisie judiciaire" },
];

const RULES = [
  {
    icon: "photo_camera",
    title: "Photos de qualité",
    desc: "Publiez au minimum 2 photos réelles de l'article. Les photos floues, trop sombres ou issues d'internet sont refusées. Pas de texte ni de filigrane sur les images.",
  },
  {
    icon: "title",
    title: "Titre clair et précis",
    desc: "Le titre doit décrire l'article honnêtement : marque, modèle, état. Exemples acceptés : « iPhone 13 Pro 256 Go – Très bon état » ou « Chaise de bureau ergonomique IKEA ».",
  },
  {
    icon: "sell",
    title: "Prix réaliste",
    desc: "Le prix doit correspondre à la valeur réelle du marché. Les prix manifestement excessifs ou symboliques (1 FCFA) seront modérés.",
  },
  {
    icon: "location_on",
    title: "Localisation exacte",
    desc: "Indiquez la ville et le quartier réels où se trouve l'article pour faciliter les remises en main propre.",
  },
  {
    icon: "inventory_2",
    title: "Un article = une annonce",
    desc: "Chaque annonce doit correspondre à un seul article ou lot clairement défini. Les annonces catalogue (\"j'ai plusieurs modèles\") sont interdites.",
  },
  {
    icon: "update",
    title: "Annonces à jour",
    desc: "Supprimez vos annonces dès que l'article est vendu. Les annonces inactives depuis 60 jours sans réponse seront archivées automatiquement.",
  },
];

export default function ReglesPage() {
  return (
    <div className="min-h-screen bg-background text-on-surface">

      {/* En-tête */}
      <header className="sticky top-0 z-50 bg-background/95 backdrop-blur border-b border-surface-container-highest">
        <div className="max-w-4xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <div className="rounded-[10px] overflow-hidden">
              <Image src="/R.png" alt="Rizen" width={32} height={32} className="h-8 w-auto object-contain" />
            </div>
            <span className="text-headline-sm text-on-secondary-fixed tracking-tight">Rizen</span>
          </Link>
          <BackButton />
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-6 py-12 md:py-16 space-y-14">

        {/* Titre */}
        <div>
          <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-secondary-container/60 text-secondary text-label-sm font-semibold mb-4">
            <span className="material-symbols-outlined text-[14px]">rule</span>
            Guide du vendeur
          </span>
          <h1 className="text-display-lg-mobile md:text-display-lg font-bold text-on-secondary-fixed tracking-tight mb-3">
            Règles de diffusion
          </h1>
          <p className="text-body-lg text-secondary max-w-2xl">
            Pour que Rizen reste un espace de confiance pour tous, chaque annonce doit respecter ces règles.
            Toute annonce non conforme sera retirée sans préavis.
          </p>
        </div>

        {/* Ce qui est autorisé */}
        <section>
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-full bg-tertiary/10 flex items-center justify-center">
              <span className="material-symbols-outlined text-tertiary text-[22px]">check_circle</span>
            </div>
            <h2 className="text-headline-md text-on-secondary-fixed">Articles autorisés</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {ALLOWED.map((item) => (
              <div key={item.label} className="flex items-center gap-3 p-3.5 rounded-2xl bg-surface-container-lowest shadow-card">
                <div className="w-9 h-9 rounded-full bg-tertiary/10 flex items-center justify-center shrink-0">
                  <span className="material-symbols-outlined text-tertiary text-[18px]">{item.icon}</span>
                </div>
                <span className="text-body-md text-on-surface">{item.label}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Ce qui est interdit */}
        <section>
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-full bg-error/10 flex items-center justify-center">
              <span className="material-symbols-outlined text-error text-[22px]">cancel</span>
            </div>
            <h2 className="text-headline-md text-on-secondary-fixed">Articles et contenus interdits</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {FORBIDDEN.map((item) => (
              <div key={item.label} className="flex items-center gap-3 p-3.5 rounded-2xl bg-error-container/30">
                <div className="w-9 h-9 rounded-full bg-error/10 flex items-center justify-center shrink-0">
                  <span className="material-symbols-outlined text-error text-[18px]">{item.icon}</span>
                </div>
                <span className="text-body-md text-on-surface">{item.label}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Règles de publication */}
        <section>
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-full bg-primary-fixed/40 flex items-center justify-center">
              <span className="material-symbols-outlined text-primary-container text-[22px]">checklist</span>
            </div>
            <h2 className="text-headline-md text-on-secondary-fixed">Règles de publication</h2>
          </div>
          <div className="space-y-3">
            {RULES.map((rule) => (
              <div key={rule.title} className="flex gap-4 p-4 rounded-2xl bg-surface-container-lowest shadow-card">
                <div className="w-10 h-10 rounded-full bg-primary-fixed/40 flex items-center justify-center shrink-0">
                  <span className="material-symbols-outlined text-primary-container text-[20px]">{rule.icon}</span>
                </div>
                <div>
                  <p className="text-label-lg text-on-secondary-fixed font-semibold mb-1">{rule.title}</p>
                  <p className="text-body-md text-secondary">{rule.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Sanctions */}
        <section className="p-6 rounded-3xl bg-on-secondary-fixed text-surface-container-lowest">
          <div className="flex items-center gap-3 mb-4">
            <span className="material-symbols-outlined text-primary-container text-[24px]">gavel</span>
            <h2 className="text-headline-sm text-surface-container-lowest">Conséquences en cas de non-respect</h2>
          </div>
          <ul className="space-y-2 text-body-md text-secondary-fixed-dim">
            {[
              "Suppression immédiate de l'annonce sans notification préalable",
              "Avertissement envoyé par email sur le compte concerné",
              "Suspension temporaire du compte (7 à 30 jours) en cas de récidive",
              "Bannissement définitif et signalement aux autorités compétentes pour les infractions graves",
            ].map((item) => (
              <li key={item} className="flex items-start gap-3">
                <span className="material-symbols-outlined text-primary-container text-[18px] mt-0.5 shrink-0">arrow_right</span>
                {item}
              </li>
            ))}
          </ul>
        </section>

        {/* Contact */}
        <section className="text-center py-4">
          <p className="text-body-lg text-secondary mb-4">
            Une question sur ces règles ? Notre équipe vous répond rapidement.
          </p>
          <div className="flex flex-wrap justify-center gap-3">
            <a
              href={WHATSAPP}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 h-[48px] px-6 rounded-full bg-tertiary text-white text-label-lg font-semibold hover:opacity-90 transition-all"
            >
              <span className="material-symbols-outlined text-[20px]">chat</span>
              Contacter sur WhatsApp
            </a>
            <a
              href="https://mail.google.com/mail/?view=cm&to=rizen.marketplace@gmail.com"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 h-[48px] px-6 rounded-full bg-surface-container-lowest shadow-card text-on-secondary-fixed text-label-lg font-semibold hover:bg-surface-container-low transition-all"
            >
              <span className="material-symbols-outlined text-[20px]">mail</span>
              rizen.marketplace@gmail.com
            </a>
          </div>
        </section>

      </main>

      {/* Footer */}
      <footer className="border-t border-surface-container-highest mt-8 py-8">
        <div className="max-w-4xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-label-sm text-secondary">
          <span>© 2026 Rizen Marketplace</span>
          <div className="flex items-center gap-4">
            <Link href="/conditions-generales" className="hover:text-on-surface transition-colors">CGU</Link>
            <span>•</span>
            <Link href="/confidentialite" className="hover:text-on-surface transition-colors">Confidentialité</Link>
            <span>•</span>
            <Link href="/regles-de-diffusion" className="text-on-surface font-semibold">Règles de diffusion</Link>
          </div>
        </div>
      </footer>

    </div>
  );
}
