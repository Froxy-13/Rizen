-- ============================================================
-- Rizen Marketplace — Migration v2
-- À exécuter dans Supabase SQL Editor (onglet SQL)
-- Idempotent : chaque ADD COLUMN est protégé par IF NOT EXISTS
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- 1. TABLE annonces — colonnes manquantes
-- ──────────────────────────────────────────────────────────────

-- État du produit : neuf | tres_bon | bon | correct
ALTER TABLE annonces
  ADD COLUMN IF NOT EXISTS etat VARCHAR DEFAULT NULL;

-- Compteur de vues (incrémenté côté serveur)
ALTER TABLE annonces
  ADD COLUMN IF NOT EXISTS vues INTEGER NOT NULL DEFAULT 0;

-- Slug URL-friendly généré automatiquement (optionnel mais utile pour SEO)
ALTER TABLE annonces
  ADD COLUMN IF NOT EXISTS slug VARCHAR DEFAULT NULL;

-- Annonce boostée/mise en avant (timestamp d'expiration, NULL = pas boostée)
ALTER TABLE annonces
  ADD COLUMN IF NOT EXISTS boost_expires_at TIMESTAMPTZ DEFAULT NULL;

-- ──────────────────────────────────────────────────────────────
-- 2. TABLE profils — colonnes manquantes
-- ──────────────────────────────────────────────────────────────

-- Badge vendeur certifié (validé manuellement par un admin)
ALTER TABLE profils
  ADD COLUMN IF NOT EXISTS certifie BOOLEAN NOT NULL DEFAULT FALSE;

-- Courte présentation du vendeur
ALTER TABLE profils
  ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT NULL;

-- Note moyenne (cache mis à jour par trigger après chaque avis)
ALTER TABLE profils
  ADD COLUMN IF NOT EXISTS note_moyenne NUMERIC(3,2) DEFAULT NULL;

-- Nombre total d'avis reçus
ALTER TABLE profils
  ADD COLUMN IF NOT EXISTS nombre_avis INTEGER NOT NULL DEFAULT 0;

-- Nombre de ventes réalisées (annonces marquées vendue)
ALTER TABLE profils
  ADD COLUMN IF NOT EXISTS nombre_ventes INTEGER NOT NULL DEFAULT 0;

-- Ville principale du vendeur (séparé du champ adresse texte libre)
ALTER TABLE profils
  ADD COLUMN IF NOT EXISTS ville VARCHAR DEFAULT NULL;

-- ──────────────────────────────────────────────────────────────
-- 3. TABLE sous_categories
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sous_categories (
  id          SERIAL PRIMARY KEY,
  categorie_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  nom         VARCHAR NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Policies RLS
ALTER TABLE sous_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lire sous-categories" ON sous_categories;
CREATE POLICY "Lire sous-categories" ON sous_categories
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "SuperAdmin gérer sous-categories" ON sous_categories;
CREATE POLICY "SuperAdmin gérer sous-categories" ON sous_categories
  FOR ALL TO authenticated USING (est_superadmin()) WITH CHECK (est_superadmin());

-- ──────────────────────────────────────────────────────────────
-- 4. Ajouter sous_categorie_id sur annonces
-- ──────────────────────────────────────────────────────────────

ALTER TABLE annonces
  ADD COLUMN IF NOT EXISTS sous_categorie_id INTEGER REFERENCES sous_categories(id) ON DELETE SET NULL;

-- ──────────────────────────────────────────────────────────────
-- 5. TABLE annonce_attributs (specs clé-valeur : taille, couleur, etc.)
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS annonce_attributs (
  id         SERIAL PRIMARY KEY,
  annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE,
  cle        VARCHAR NOT NULL,   -- ex: "Couleur", "Taille", "Marque"
  valeur     VARCHAR NOT NULL,   -- ex: "Noir", "XL", "Samsung"
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE annonce_attributs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lire attributs" ON annonce_attributs;
CREATE POLICY "Lire attributs" ON annonce_attributs
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Gérer attributs" ON annonce_attributs;
CREATE POLICY "Gérer attributs" ON annonce_attributs
  FOR ALL TO public
  USING (
    EXISTS (
      SELECT 1 FROM annonces a
      WHERE a.id = annonce_id AND (a.utilisateur_id = auth.uid() OR est_superadmin())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM annonces a
      WHERE a.id = annonce_id AND (a.utilisateur_id = auth.uid() OR est_superadmin())
    )
  );

-- ──────────────────────────────────────────────────────────────
-- 6. TABLE annonce_vues (vues uniques par utilisateur/IP)
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS annonce_vues (
  id          SERIAL PRIMARY KEY,
  annonce_id  INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE,
  utilisateur_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- NULL si visiteur anonyme
  ip_hash     VARCHAR DEFAULT NULL,  -- hash de l'IP pour les anonymes
  vu_le       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_annonce_vues_annonce ON annonce_vues(annonce_id);

ALTER TABLE annonce_vues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Insérer vue" ON annonce_vues;
CREATE POLICY "Insérer vue" ON annonce_vues
  FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Lire vues (propriétaire)" ON annonce_vues;
CREATE POLICY "Lire vues (propriétaire)" ON annonce_vues
  FOR SELECT TO public
  USING (
    EXISTS (
      SELECT 1 FROM annonces a
      WHERE a.id = annonce_id AND a.utilisateur_id = auth.uid()
    )
    OR est_superadmin()
  );

-- ──────────────────────────────────────────────────────────────
-- 7. TABLE transactions — colonnes manquantes
-- ──────────────────────────────────────────────────────────────

-- On s'assure que les colonnes essentielles existent
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS annonce_id INTEGER REFERENCES annonces(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS montant    NUMERIC DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS statut     VARCHAR DEFAULT 'en_attente',
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- ──────────────────────────────────────────────────────────────
-- 8. TRIGGER — mise à jour note_moyenne sur profils après avis
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION maj_note_vendeur()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profils
  SET
    note_moyenne = (
      SELECT ROUND(AVG(note)::NUMERIC, 2)
      FROM avis
      WHERE vendeur_id = COALESCE(NEW.vendeur_id, OLD.vendeur_id)
    ),
    nombre_avis = (
      SELECT COUNT(*)
      FROM avis
      WHERE vendeur_id = COALESCE(NEW.vendeur_id, OLD.vendeur_id)
    )
  WHERE id = COALESCE(NEW.vendeur_id, OLD.vendeur_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_maj_note_vendeur_insert ON avis;
CREATE TRIGGER trg_maj_note_vendeur_insert
  AFTER INSERT ON avis
  FOR EACH ROW EXECUTE FUNCTION maj_note_vendeur();

DROP TRIGGER IF EXISTS trg_maj_note_vendeur_delete ON avis;
CREATE TRIGGER trg_maj_note_vendeur_delete
  AFTER DELETE ON avis
  FOR EACH ROW EXECUTE FUNCTION maj_note_vendeur();

-- ──────────────────────────────────────────────────────────────
-- 9. TRIGGER — incrémenter nombre_ventes quand annonce → vendue
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION maj_nombre_ventes()
RETURNS TRIGGER AS $$
BEGIN
  -- Incrémenter si on passe à "vendue"
  IF NEW.statut = 'vendue' AND OLD.statut <> 'vendue' THEN
    UPDATE profils
    SET nombre_ventes = nombre_ventes + 1
    WHERE id = NEW.utilisateur_id;
  END IF;
  -- Décrémenter si on revient de "vendue" (ex: réactivation admin)
  IF OLD.statut = 'vendue' AND NEW.statut <> 'vendue' THEN
    UPDATE profils
    SET nombre_ventes = GREATEST(nombre_ventes - 1, 0)
    WHERE id = NEW.utilisateur_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_maj_nombre_ventes ON annonces;
CREATE TRIGGER trg_maj_nombre_ventes
  AFTER UPDATE OF statut ON annonces
  FOR EACH ROW EXECUTE FUNCTION maj_nombre_ventes();

-- ──────────────────────────────────────────────────────────────
-- 10. TRIGGER — updated_at automatique sur annonces et profils
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_annonces_updated_at ON annonces;
CREATE TRIGGER trg_annonces_updated_at
  BEFORE UPDATE ON annonces
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_profils_updated_at ON profils;
CREATE TRIGGER trg_profils_updated_at
  BEFORE UPDATE ON profils
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ──────────────────────────────────────────────────────────────
-- 11. FONCTION creer_conversation
--     Appelée depuis SellerStickyCard via supabase.rpc()
--     Crée ou retourne la conversation existante pour
--     (acheteur actuel, annonce, vendeur)
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION creer_conversation(
  p_annonce_id INTEGER,
  p_vendeur_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_acheteur_id UUID := auth.uid();
  v_conv_id     INTEGER;
BEGIN
  -- Vérifications basiques
  IF v_acheteur_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;
  IF v_acheteur_id = p_vendeur_id THEN
    RAISE EXCEPTION 'Vous ne pouvez pas contacter votre propre annonce';
  END IF;

  -- Chercher une conversation existante entre acheteur et vendeur pour cette annonce
  SELECT c.id INTO v_conv_id
  FROM conversations c
  JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.utilisateur_id = v_acheteur_id
  JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.utilisateur_id = p_vendeur_id
  WHERE c.annonce_id = p_annonce_id
  LIMIT 1;

  -- Si elle existe, la retourner directement
  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  -- Sinon créer la conversation
  INSERT INTO conversations (annonce_id, statut)
  VALUES (p_annonce_id, 'active')
  RETURNING id INTO v_conv_id;

  -- Ajouter les deux participants
  INSERT INTO conversation_participants (conversation_id, utilisateur_id)
  VALUES (v_conv_id, v_acheteur_id), (v_conv_id, p_vendeur_id);

  RETURN v_conv_id;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- 12. FONCTION incrementer_vues
--     Incrémente annonces.vues + insère dans annonce_vues
--     Appelée côté client : supabase.rpc('incrementer_vues', { p_annonce_id })
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION incrementer_vues(p_annonce_id INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Incrémenter le compteur
  UPDATE annonces SET vues = vues + 1 WHERE id = p_annonce_id;

  -- Enregistrer la vue unique (dédupliquée par utilisateur sur 24h)
  IF auth.uid() IS NOT NULL THEN
    INSERT INTO annonce_vues (annonce_id, utilisateur_id)
    SELECT p_annonce_id, auth.uid()
    WHERE NOT EXISTS (
      SELECT 1 FROM annonce_vues
      WHERE annonce_id = p_annonce_id
        AND utilisateur_id = auth.uid()
        AND vu_le > now() - INTERVAL '24 hours'
    );
  END IF;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- 13. Données initiales — sous-catégories courantes
-- ──────────────────────────────────────────────────────────────

-- Remplir si les catégories existent déjà (INSERT IGNORE pattern)
INSERT INTO sous_categories (categorie_id, nom)
SELECT c.id, s.nom
FROM categories c
JOIN (
  VALUES
    ('Électronique',     'Téléphones & Smartphones'),
    ('Électronique',     'Ordinateurs & Tablettes'),
    ('Électronique',     'Audio & Casques'),
    ('Électronique',     'Appareils photo'),
    ('Électronique',     'TV & Vidéo'),
    ('Électronique',     'Jeux vidéo & Consoles'),
    ('Vêtements & Mode', 'Vêtements homme'),
    ('Vêtements & Mode', 'Vêtements femme'),
    ('Vêtements & Mode', 'Chaussures'),
    ('Vêtements & Mode', 'Accessoires'),
    ('Maison & Décoration', 'Meubles'),
    ('Maison & Décoration', 'Électroménager'),
    ('Maison & Décoration', 'Décoration'),
    ('Véhicules',        'Voitures'),
    ('Véhicules',        'Motos & Scooters'),
    ('Véhicules',        'Pièces & Accessoires'),
    ('Sport',            'Fitness & Musculation'),
    ('Sport',            'Sports collectifs'),
    ('Sport',            'Sports nautiques'),
    ('Immobilier',       'Location'),
    ('Immobilier',       'Vente'),
    ('Livres',           'Romans & Littérature'),
    ('Livres',           'Scolaire & Universitaire'),
    ('Beauté',           'Soins visage & Corps'),
    ('Beauté',           'Parfums')
) AS s(cat_nom, nom) ON LOWER(c.nom) = LOWER(s.cat_nom)
WHERE NOT EXISTS (
  SELECT 1 FROM sous_categories sc
  WHERE sc.categorie_id = c.id AND LOWER(sc.nom) = LOWER(s.nom)
);

-- ──────────────────────────────────────────────────────────────
-- 11. TABLE messages — accusé de lecture
-- ──────────────────────────────────────────────────────────────

-- lu = true quand le destinataire a ouvert la conversation
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS lu BOOLEAN NOT NULL DEFAULT FALSE;

-- Autoriser la mise à jour de lu par l'utilisateur authentifié
-- (le destinataire marque les messages de l'autre comme lus)
DROP POLICY IF EXISTS "Marquer message lu" ON messages;
CREATE POLICY "Marquer message lu" ON messages
  FOR UPDATE TO authenticated
  USING (
    sender_id != auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id
        AND cp.utilisateur_id = auth.uid()
    )
  )
  WITH CHECK (lu = TRUE);

-- ──────────────────────────────────────────────────────────────
-- Fin de la migration
-- ──────────────────────────────────────────────────────────────
