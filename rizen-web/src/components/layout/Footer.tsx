import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-navy text-white/70">
      <div className="container-rizen py-16">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          {/* Brand */}
          <div className="md:col-span-1 space-y-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white font-bold text-sm">R</div>
              <span className="font-bold text-white text-lg">Rizen</span>
            </div>
            <p className="text-sm leading-relaxed">
              La marketplace de confiance pour acheter et vendre des articles d&apos;occasion au Sénégal.
            </p>
            <p className="text-xs text-white/40">Fait avec ❤️ au Sénégal 🇸🇳</p>
          </div>

          {/* Découvrir */}
          <div className="space-y-4">
            <h4 className="text-white font-semibold text-sm uppercase tracking-wider">Découvrir</h4>
            <ul className="space-y-2 text-sm">
              {["Toutes les annonces", "Électronique", "Vêtements", "Maison", "Véhicules"].map((item) => (
                <li key={item}>
                  <Link href="/decouvrir" className="hover:text-white transition-colors">{item}</Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Aide */}
          <div className="space-y-4">
            <h4 className="text-white font-semibold text-sm uppercase tracking-wider">Aide</h4>
            <ul className="space-y-2 text-sm">
              {["Comment ça marche", "Paiement sécurisé", "Livraison", "Contact", "FAQ"].map((item) => (
                <li key={item}>
                  <Link href="#" className="hover:text-white transition-colors">{item}</Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Légal */}
          <div className="space-y-4">
            <h4 className="text-white font-semibold text-sm uppercase tracking-wider">Légal</h4>
            <ul className="space-y-2 text-sm">
              {["Conditions d'utilisation", "Politique de confidentialité", "Cookies", "Mentions légales"].map((item) => (
                <li key={item}>
                  <Link href="#" className="hover:text-white transition-colors">{item}</Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="border-t border-white/10 pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-white/40">
          <p>© 2026 Rizen. Tous droits réservés.</p>
          <div className="flex items-center gap-4">
            <Link href="#" className="hover:text-white/70 transition-colors">Twitter</Link>
            <Link href="#" className="hover:text-white/70 transition-colors">Instagram</Link>
            <Link href="#" className="hover:text-white/70 transition-colors">Facebook</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
