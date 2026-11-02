# 📱 RIZEN — Documentation Complète du Projet Backend

> **Document de handoff** — Toutes les informations nécessaires pour comprendre l'état actuel du projet et continuer le développement.

---

## 1. Présentation du Projet

### Description
**Rizen** est une application mobile de marketplace de seconde main ciblant le marché sénégalais. Elle permet aux utilisateurs d'acheter et de vendre des articles d'occasion, avec des fonctionnalités de messagerie, négociation de prix, système d'avis, et modération par un SuperAdmin.

### Inspirations
- Vinted
- Leboncoin

### Marché cible
Sénégal (Dakar et autres villes)

### Technologie choisie
| Couche | Technologie |
|---|---|
| Frontend mobile | Flutter (à venir) |
| Backend / Base de données | Supabase (PostgreSQL) |
| Authentification | Supabase Auth |
| Stockage fichiers | Supabase Storage ✅ Configuré |
| Tests API | Postman |

---

## 2. Contexte Académique

- **Étudiant :** Alpha Diallo
- **Formation :** Licence 3 GLAR (Génie Logiciel et Administration Réseaux)
- **École :** ESTM (École Supérieure de Technologie et de Management), Dakar, Sénégal
- **Type de projet :** Mémoire de fin de cycle
- **Entreprise d'accueil :** ITEA Group (stage)
- **Encadrant :** A validé les diagrammes UML (diagramme de classe + cas d'utilisation)

---

## 3. Accès au Projet Supabase

| Paramètre | Valeur |
|---|---|
| **Nom du projet** | RizenDB |
| **Project URL** | `https://wzujxtmjaojdqipqfkwn.supabase.co` |
| **Dashboard** | https://supabase.com/dashboard/project/wzujxtmjaojdqipqfkwn |
| **Région** | West EU (Ireland) — eu-west-1 |
| **Plan** | Free |
| **Status** | Healthy ✅ |
| **anon key** | Disponible dans Project Settings → API → anon public |
| **service_role key** | Disponible dans Project Settings → API (NE PAS exposer côté client) |

> ⚠️ **Important :** Ne jamais exposer la `service_role key` dans le code client Flutter. Utiliser uniquement la `anon key` côté application.

---

## 4. Diagramme de Classe (UML — Validé par l'encadrant)

### Acteurs / Classes principales

| Classe | Rôle |
|---|---|
| `Personne` | Classe parente abstraite (héritage vers Utilisateur et SuperAdmin) |
| `Utilisateur` | Utilisateur standard de la plateforme |
| `SuperAdmin` | Administrateur avec droits de modération |
| `Annonce` | Article mis en vente |
| `Categorie` | Catégorie d'une annonce |
| `ImageAnnonce` | Images associées à une annonce |
| `Localisation` | Ville et quartier d'une annonce |
| `Negociation` | Proposition de prix entre acheteur et vendeur |
| `Conversation` | Fil de discussion entre deux utilisateurs |
| `Message` | Message dans une conversation |
| `Transaction` | Achat finalisé |
| `Paiement` | Détails du paiement d'une transaction |
| `Avis` | Note et commentaire laissé sur une annonce |
| `Favori` | Annonce sauvegardée par un utilisateur |
| `Signalement` | Signalement d'une annonce par un utilisateur |
| `Notification` | Notification système envoyée à un utilisateur |

### Relations clés (issues du diagramme)
- `Personne` → `Utilisateur` et `SuperAdmin` (héritage, triangle blanc)
- `Utilisateur` publie `0..*` `Annonce`
- `Utilisateur` initie `0..*` `Negociation`
- `Utilisateur` participe à `0..*` `Conversation` (composition)
- `Conversation` contient `0..*` `Message`
- `Utilisateur` émet `0..*` `Favori`
- `Annonce` appartient à `1` `Categorie`
- `Annonce` possède `0..*` `ImageAnnonce`
- `Annonce` a `1` `Localisation`
- `Annonce` reçoit `0..*` `Avis`
- `Transaction` possède `1` `Paiement`
- `SuperAdmin` suspend `Utilisateur`, traite `Signalement`, modère `Annonce`

---

## 5. Structure de la Base de Données (PostgreSQL — Supabase)

### Vue d'ensemble des tables

| Table | Description |
|---|---|
| `profils` | Données des utilisateurs (liée à auth.users) |
| `categories` | Catégories d'annonces |
| `annonces` | Annonces publiées |
| `images_annonce` | Images des annonces |
| `negociations` | Négociations de prix |
| `conversations` | Fils de discussion |
| `conversation_participants` | Table de liaison conversation ↔ utilisateur |
| `messages` | Messages dans les conversations |
| `transactions` | Achats finalisés |
| `paiements` | Détails de paiement |
| `avis` | Avis sur les annonces |
| `favoris` | Annonces favorites |
| `signalements` | Signalements d'annonces |
| `notifications` | Notifications utilisateurs |

---

### Détail des tables

#### `profils`
```sql
id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
nom VARCHAR(100) NOT NULL
prenom VARCHAR(100) NOT NULL
email VARCHAR(255) NOT NULL UNIQUE
telephone VARCHAR(20)
photo TEXT
adresse TEXT
date_inscription TIMESTAMP WITH TIME ZONE DEFAULT NOW()
statut VARCHAR(20) DEFAULT 'actif' -- 'actif' | 'suspendu' | 'banni'
role VARCHAR(20) DEFAULT 'utilisateur' -- 'utilisateur' | 'superadmin'
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `categories`
```sql
id SERIAL PRIMARY KEY
nom VARCHAR(100) NOT NULL
description TEXT
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

**Données pré-remplies (7 catégories) :**
1. Électronique
2. Vêtements & Mode
3. Mobilier & Maison
4. Véhicules
5. Livres & Éducation
6. Sport & Loisirs
7. Autres

> ⚠️ Les catégories "Immobilier" et "Services" ont été supprimées.

#### `annonces`
```sql
id SERIAL PRIMARY KEY
titre VARCHAR(255) NOT NULL
description TEXT NOT NULL
prix_initial DECIMAL(10,2) NOT NULL
prix_actuel DECIMAL(10,2) NOT NULL
date_publication TIMESTAMP WITH TIME ZONE DEFAULT NOW()
statut VARCHAR(20) DEFAULT 'active' -- 'active' | 'vendue' | 'suspendue' | 'desactivee'
utilisateur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
categorie_id INTEGER REFERENCES categories(id) ON DELETE SET NULL
ville VARCHAR(100)
quartier VARCHAR(100)
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `images_annonce`
```sql
id SERIAL PRIMARY KEY
annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE
url_image TEXT NOT NULL
ordre INTEGER DEFAULT 0
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `negociations`
```sql
id SERIAL PRIMARY KEY
annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE
acheteur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
prix_propose DECIMAL(10,2) NOT NULL
date_proposition TIMESTAMP WITH TIME ZONE DEFAULT NOW()
statut VARCHAR(20) DEFAULT 'en_attente' -- 'en_attente' | 'acceptee' | 'refusee' | 'annulee'
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `conversations`
```sql
id SERIAL PRIMARY KEY
date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
statut VARCHAR(20) DEFAULT 'active' -- 'active' | 'archivee' | 'bloquee'
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `conversation_participants`
```sql
conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE
utilisateur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
PRIMARY KEY (conversation_id, utilisateur_id)
```

#### `messages`
```sql
id SERIAL PRIMARY KEY
conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE
sender_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
contenu TEXT NOT NULL
date_envoi TIMESTAMP WITH TIME ZONE DEFAULT NOW()
lu BOOLEAN DEFAULT FALSE
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `transactions`
```sql
id SERIAL PRIMARY KEY
annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE RESTRICT
acheteur_id UUID NOT NULL REFERENCES profils(id) ON DELETE RESTRICT
vendeur_id UUID NOT NULL REFERENCES profils(id) ON DELETE RESTRICT
date_transaction TIMESTAMP WITH TIME ZONE DEFAULT NOW()
prix_final DECIMAL(10,2) NOT NULL
statut VARCHAR(20) DEFAULT 'en_cours' -- 'en_cours' | 'completee' | 'annulee' | 'litige'
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `paiements`
```sql
id SERIAL PRIMARY KEY
transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE RESTRICT
montant DECIMAL(10,2) NOT NULL
methode VARCHAR(50) NOT NULL -- 'wave' | 'orange_money' | 'free_money' | 'carte' | 'especes'
reference VARCHAR(255) UNIQUE
date_paiement TIMESTAMP WITH TIME ZONE DEFAULT NOW()
statut VARCHAR(20) DEFAULT 'en_attente' -- 'en_attente' | 'confirme' | 'echoue' | 'rembourse'
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `avis`
```sql
id SERIAL PRIMARY KEY
annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE
utilisateur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
note INTEGER NOT NULL CHECK (note BETWEEN 1 AND 5)
commentaire TEXT
date_avis TIMESTAMP WITH TIME ZONE DEFAULT NOW()
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
UNIQUE (annonce_id, utilisateur_id) -- un seul avis par utilisateur par annonce
```

#### `favoris`
```sql
id SERIAL PRIMARY KEY
utilisateur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE
date_ajout TIMESTAMP WITH TIME ZONE DEFAULT NOW()
UNIQUE (utilisateur_id, annonce_id) -- pas de doublon
```

#### `signalements`
```sql
id SERIAL PRIMARY KEY
annonce_id INTEGER NOT NULL REFERENCES annonces(id) ON DELETE CASCADE
utilisateur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
raison VARCHAR(100) NOT NULL
description TEXT
date_signalement TIMESTAMP WITH TIME ZONE DEFAULT NOW()
statut VARCHAR(20) DEFAULT 'en_attente' -- 'en_attente' | 'traite' | 'rejete'
traite_par UUID REFERENCES profils(id) ON DELETE SET NULL
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

#### `notifications`
```sql
id SERIAL PRIMARY KEY
utilisateur_id UUID NOT NULL REFERENCES profils(id) ON DELETE CASCADE
titre VARCHAR(255) NOT NULL
message TEXT NOT NULL
type VARCHAR(50) NOT NULL -- 'annonce' | 'message' | 'negociation' | 'transaction' | 'signalement' | 'systeme'
lu BOOLEAN DEFAULT FALSE
date_notification TIMESTAMP WITH TIME ZONE DEFAULT NOW()
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

---

### Trigger automatique (inscription)
```sql
CREATE OR REPLACE FUNCTION public.creer_profil_utilisateur()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profils (id, nom, prenom, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nom', ''),
    COALESCE(NEW.raw_user_meta_data->>'prenom', ''),
    NEW.email,
    'utilisateur'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.creer_profil_utilisateur();
```

### Trigger blocage compte suspendu
```sql
CREATE OR REPLACE FUNCTION public.verifier_statut_utilisateur()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.profils
    WHERE id = NEW.user_id
    AND statut = 'suspendu'
  ) THEN
    RAISE EXCEPTION 'Compte suspendu. Veuillez contacter l''administrateur.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER verifier_statut_avant_connexion
  AFTER INSERT ON auth.sessions
  FOR EACH ROW EXECUTE FUNCTION public.verifier_statut_utilisateur();
```

---

## 6. Row Level Security (RLS)

### Fonction utilitaire SuperAdmin
```sql
CREATE OR REPLACE FUNCTION public.est_superadmin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profils
    WHERE id = auth.uid()
    AND role = 'superadmin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Politiques par table

| Table | Qui peut faire quoi |
|---|---|
| `profils` | Chacun voit/modifie son profil. SuperAdmin voit et modifie tout. |
| `annonces` | Tout le monde lit les annonces actives. Propriétaire ou SuperAdmin modifie/supprime. |
| `images_annonce` | Tout le monde lit. Propriétaire de l'annonce ou SuperAdmin gère. |
| `categories` | Tout le monde lit. SuperAdmin gère. |
| `negociations` | Acheteur et vendeur concernés voient. Acheteur crée. Vendeur accepte/refuse. |
| `conversations` | Participants voient. N'importe qui crée. |
| `messages` | Participants de la conversation voient et envoient. |
| `avis` | Tout le monde lit. Utilisateur connecté crée le sien. Utilisateur ou SuperAdmin supprime. |
| `favoris` | Chacun gère ses propres favoris. |
| `signalements` | Utilisateur crée. SuperAdmin voit, traite et modifie. |
| `notifications` | Chacun voit les siennes. SuperAdmin gère tout. |
| `transactions` | Acheteur et vendeur concernés voient. Acheteur crée. |
| `paiements` | Acheteur et vendeur concernés voient. SuperAdmin gère. |

---

## 7. Supabase Storage — Images des annonces

### Bucket configuré
| Paramètre | Valeur |
|---|---|
| **Nom du bucket** | `annonces-images` |
| **Type** | Public |
| **URL de base** | `https://wzujxtmjaojdqipqfkwn.supabase.co/storage/v1/object/public/annonces-images/` |

### Politiques Storage
| Politique | Opération | Condition |
|---|---|---|
| Upload images | INSERT | `bucket_id = 'annonces-images' AND auth.role() = 'authenticated'` |
| Lire images | SELECT | `true` (public) |

### Upload via Postman
```
POST https://wzujxtmjaojdqipqfkwn.supabase.co/storage/v1/object/annonces-images/{nom_fichier.jpg}
Headers: apikey, Authorization: Bearer token, Content-Type: image/jpeg
Body: Binary → sélectionner le fichier
```

---

## 8. API Supabase — Endpoints testés et validés

> **Base URL :** `https://wzujxtmjaojdqipqfkwn.supabase.co`
>
> **Headers communs :**
> ```
> apikey: {{api}}
> Authorization: Bearer {{access_token}}
> Content-Type: application/json  (POST/PATCH)
> Prefer: return=representation   (POST/PATCH)
> ```
>
> ⚠️ Le `access_token` expire après 1 heure → relancer Connexion_user.

---

### 🔐 Authentification ✅

#### Inscription
```
POST /auth/v1/signup
Body:
{
  "email": "user@example.com",
  "password": "motdepasse123",
  "data": { "nom": "Diallo", "prenom": "Alpha" }
}
```

#### Connexion
```
POST /auth/v1/token?grant_type=password
Body:
{
  "email": "user@example.com",
  "password": "motdepasse123"
}
Réponse: access_token + user.id (sauvegardés automatiquement via script Postman)
```

**Script Post-response sur Connexion_user :**
```javascript
var response = pm.response.json();
pm.collectionVariables.set("access_token", response.access_token);
pm.collectionVariables.set("user_id", response.user.id);
```

---

### 📢 Annonces ✅

```
POST   /rest/v1/annonces                          → Créer
GET    /rest/v1/annonces?select=*                 → Lire toutes
GET    /rest/v1/annonces?id=eq.{ID}               → Lire par ID
PATCH  /rest/v1/annonces?id=eq.{ID}               → Modifier
DELETE /rest/v1/annonces?id=eq.{ID}               → Supprimer
```

Body création :
```json
{
  "titre": "iPhone 13 Pro",
  "description": "Très bon état",
  "prix_initial": 350000,
  "prix_actuel": 350000,
  "categorie_id": 1,
  "ville": "Dakar",
  "quartier": "Plateau",
  "utilisateur_id": "{{user_id}}"
}
```

---

### 🖼️ Images Annonces ✅

```
POST /rest/v1/images_annonce                                    → Ajouter
GET  /rest/v1/images_annonce?annonce_id=eq.{ID}&order=ordre.asc → Lire
```

Body :
```json
{
  "annonce_id": 1,
  "url_image": "https://wzujxtmjaojdqipqfkwn.supabase.co/storage/v1/object/public/annonces-images/fichier.jpg",
  "ordre": 1
}
```

---

### ❤️ Favoris ✅

```
POST   /rest/v1/favoris                                                          → Ajouter
GET    /rest/v1/favoris?utilisateur_id=eq.{{user_id}}&select=*,annonces(*)       → Lister
DELETE /rest/v1/favoris?utilisateur_id=eq.{{user_id}}&annonce_id=eq.{ID}         → Supprimer
```

Body ajout :
```json
{
  "utilisateur_id": "{{user_id}}",
  "annonce_id": 1
}
```
> Contrainte UNIQUE : une seule fois par annonce par utilisateur.

---

### 🔄 Négociations ✅

```
POST  /rest/v1/negociations                              → Créer
GET   /rest/v1/negociations?annonce_id=eq.{ID}&select=* → Lister
PATCH /rest/v1/negociations?id=eq.{ID}                  → Accepter/Refuser
```

Body création :
```json
{
  "annonce_id": 1,
  "acheteur_id": "{{user_id}}",
  "prix_propose": 280000
}
```

Body accepter/refuser :
```json
{ "statut": "acceptee" }
{ "statut": "refusee" }
```

---

### 💬 Messagerie ✅

```
POST  /rest/v1/conversations                                                    → Créer conversation
POST  /rest/v1/conversation_participants                                         → Ajouter participant
POST  /rest/v1/messages                                                          → Envoyer message
GET   /rest/v1/messages?conversation_id=eq.{ID}&select=*&order=date_envoi.asc   → Lire messages
PATCH /rest/v1/messages?id=eq.{ID}                                               → Marquer lu
```

Body message :
```json
{
  "conversation_id": 1,
  "sender_id": "{{user_id}}",
  "contenu": "Bonjour, est-ce toujours disponible ?"
}
```

---

### ⭐ Avis ✅

```
POST   /rest/v1/avis                              → Laisser un avis
GET    /rest/v1/avis?annonce_id=eq.{ID}&select=*  → Lire les avis
DELETE /rest/v1/avis?id=eq.{ID}                   → Supprimer
```

Body :
```json
{
  "annonce_id": 1,
  "utilisateur_id": "{{user_id}}",
  "note": 4,
  "commentaire": "Vendeur sérieux, article conforme"
}
```
> Note entre 1 et 5. Un seul avis par utilisateur par annonce.

---

### 🚩 Signalements ✅

```
POST  /rest/v1/signalements          → Signaler (utilisateur)
GET   /rest/v1/signalements?select=* → Lister tous (SuperAdmin uniquement)
PATCH /rest/v1/signalements?id=eq.{ID} → Traiter (SuperAdmin uniquement)
```

Body signalement :
```json
{
  "annonce_id": 1,
  "utilisateur_id": "{{user_id}}",
  "raison": "Contenu inapproprié",
  "description": "Cette annonce contient des informations fausses"
}
```

Body traitement (SuperAdmin) :
```json
{
  "statut": "traite",
  "traite_par": "{{user_id}}"
}
```

---

### 👑 SuperAdmin ✅

#### Créer le compte SuperAdmin
1. Inscrire via `/auth/v1/signup` avec email `admin@rizen.sn`
2. Exécuter dans SQL Editor :
```sql
UPDATE profils SET role = 'superadmin' WHERE email = 'admin@rizen.sn';
```

#### Actions
```
PATCH /rest/v1/profils?id=eq.{UUID}   → Suspendre : { "statut": "suspendu" }
PATCH /rest/v1/profils?id=eq.{UUID}   → Réactiver : { "statut": "actif" }
PATCH /rest/v1/annonces?id=eq.{ID}    → Désactiver : { "statut": "desactivee" }
```

> Workflow : traiter signalement → désactiver annonce (2 requêtes enchaînées).

---

## 9. Collection Postman

### Variables de collection configurées
| Variable | Remplie par | Usage |
|---|---|---|
| `access_token` | Script Post-response Connexion_user | `Bearer {{access_token}}` dans Authorization |
| `user_id` | Script Post-response Connexion_user | `"{{user_id}}"` dans les Body |
| `api` | Manuel (anon key) | `{{api}}` dans apikey header |

### Structure complète
```
Rizen/
├── Authentification/
│   ├── POST Inscription_user
│   └── POST Connexion_user  ← Script post-response configuré
├── Annonces/
│   ├── POST Créer_annonce
│   ├── GET  Lire_annonces
│   ├── GET  Lire_All_annonces
│   ├── GET  Lire_annonce_ByID
│   ├── POST Ajouter_image
│   ├── GET  Lire_images_annonce
│   ├── PATCH Modifier_annonce
│   └── DELETE Supprimer_annonces
├── Favoris/
│   ├── POST Ajouter_favoris
│   ├── GET  Lister_ses_favoris
│   └── DELETE Supprimer_favoris
├── Négociations/
│   ├── POST Créer_négociation
│   ├── GET  Lister_négociations
│   ├── PATCH Accepter_négociation
│   └── PATCH Refuser_négociation
├── Messagerie/
│   ├── POST Créer_conversation
│   ├── POST Ajouter_participants
│   ├── POST Envoyer_message
│   ├── GET  Lire_message_conv
│   └── PATCH Marquer_message_lu
├── Avis/
│   ├── POST Laisser_avis
│   ├── GET  Lister_avis
│   └── DELETE Supprimer_avis
├── Signalements/
│   ├── POST Signaler_annonce
│   ├── GET  Lister_signalements_SuperAdmin
│   └── PATCH Traiter_signalement_SuperAdmin
└── SuperAdmin/
    ├── POST Inscription_SuperAdmin
    ├── PATCH Suspendre_user
    ├── PATCH Reactiver_user
    └── PATCH Desactiver_annonce
```

---

## 10. État d'avancement

### ✅ Backend — 100% Terminé et Sécurisé

| Tâche | Statut |
|---|---|
| Diagramme de classe UML | ✅ Validé encadrant |
| Diagramme de cas d'utilisation | ✅ Validé encadrant |
| Création projet Supabase | ✅ |
| Création des 13 tables SQL | ✅ |
| Catégories pré-remplies (7) | ✅ |
| Trigger inscription automatique | ✅ |
| Trigger blocage compte suspendu | ✅ |
| Auth Email/Password | ✅ |
| Supabase Storage configuré | ✅ |
| RLS configuré sur toutes les tables | ✅ |
| Séparation droits utilisateur / SuperAdmin | ✅ |
| Script Postman auto-token | ✅ |
| Test Postman — Inscription / Connexion | ✅ |
| Test Postman — CRUD Annonces | ✅ |
| Test Postman — Images Annonces | ✅ |
| Test Postman — Favoris | ✅ |
| Test Postman — Négociations | ✅ |
| Test Postman — Messagerie | ✅ |
| Test Postman — Avis | ✅ |
| Test Postman — Signalements | ✅ |
| Test Postman — SuperAdmin | ✅ |

### ❌ Reste à faire

| Tâche | Priorité |
|---|---|
| Intégration Flutter | Prochaine étape |

---

## 11. Points importants à savoir

### Token JWT
- Expire après **1 heure**
- Relancer **Connexion_user** → le script remplit automatiquement `{{access_token}}` et `{{user_id}}`

### Compte SuperAdmin
- Email : `admin@rizen.sn`
- Rôle défini manuellement via SQL : `UPDATE profils SET role = 'superadmin' WHERE email = 'admin@rizen.sn'`
- En production, création SuperAdmin uniquement via SQL

### Contraintes importantes
- Un seul avis par utilisateur par annonce (UNIQUE)
- Un seul favori par utilisateur par annonce (UNIQUE)
- `utilisateur_id` obligatoire pour créer une annonce
- Note d'un avis entre 1 et 5
- Utilisateur suspendu → connexion bloquée automatiquement

### Sécurité RLS
- Toutes les tables ont le RLS activé
- Chaque utilisateur n'accède qu'à ses propres données
- Le SuperAdmin a accès à tout
- Les annonces actives sont visibles par tous

---

## 12. Prochaines étapes

1. **Démarrer Flutter** — installer le package `supabase_flutter`
2. **Connecter Flutter à Supabase** avec Project URL + anon key
3. **Développer les écrans** fonctionnalité par fonctionnalité

---

*Document mis à jour le 27/06/2026 — Projet Rizen, Alpha Diallo, ESTM Dakar*

---

## 13. Développement Flutter

### Configuration projet
- **IDE :** Android Studio
- **Package principal :** `supabase_flutter: ^2.0.0`
- **Autres packages :** `cached_network_image`, `image_picker`
- **Initialisation Supabase** dans `main.dart` avec Project URL + anon key ✅
- **Test connexion** : "Rizen App — Connected ✅" affiché ✅

### Ordre de développement (écran par écran)

| Ordre | Écran | Statut |
|---|---|---|
| 1 | Authentification (Inscription / Connexion / Déconnexion) | ❌ |
| 2 | Accueil — Liste des annonces | ❌ |
| 3 | Détail annonce | ❌ |
| 4 | Créer annonce (avec photos) | ❌ |
| 5 | Favoris | ❌ |
| 6 | Messagerie | ❌ |
| 7 | Négociations | ❌ |
| 8 | Profil utilisateur | ❌ |
| 9 | Avis | ❌ |
| 10 | Signalements | ❌ |
| 11 | SuperAdmin | ❌ |

---

*Document mis à jour le 27/06/2026 — Projet Rizen, Alpha Diallo, ESTM Dakar*

---

## 14. Règles UI/UX de l'application

### Règles strictes
- **Aucun emoji** dans l'application — uniquement des icônes Flutter (`Icons.xxx`)
- Icônes représentatives de l'action demandée

### Accès selon statut de connexion

| Fonctionnalité | Non connecté | Connecté |
|---|---|---|
| Voir les annonces | ✅ Autorisé | ✅ Autorisé |
| Voir le détail d'une annonce | ✅ Autorisé | ✅ Autorisé |
| Publier une annonce | ❌ Connexion requise | ✅ Autorisé |
| Ajouter aux favoris | ❌ Connexion requise | ✅ Autorisé |
| Envoyer un message | ❌ Connexion requise | ✅ Autorisé |
| Négocier un prix | ❌ Connexion requise | ✅ Autorisé |
| Laisser un avis | ❌ Connexion requise | ✅ Autorisé |
| Signaler une annonce | ❌ Connexion requise | ✅ Autorisé |

### Déconnexion
- Côté Flutter : `Supabase.instance.client.auth.signOut()` invalide le token côté serveur
- Le token devient inutilisable immédiatement après déconnexion
- RLS annonces mis à jour : les annonces actives sont visibles sans token

### Couleurs de l'application
*À définir — en attente des couleurs du projet*

---

*Document mis à jour le 27/06/2026 — Projet Rizen, Alpha Diallo, ESTM Dakar*

---

## 15. Système de Design (Design System)

> Basé sur la maquette Google Stitch — sert de référence pour le développement Flutter.
> La maquette couvre uniquement le côté utilisateur (pas SuperAdmin) et n'est pas complète à 100%. Elle sert de guide visuel.

---

### Marque & Style

Le système de design de cette marketplace mobile est construit sur une fondation de **"Minimalisme Chaleureux"**. Il cible un public sénégalais moderne à la recherche d'un environnement fiable, sophistiqué et épuré pour le commerce entre particuliers. L'esthétique s'éloigne de la nature chaotique des petites annonces traditionnelles, adoptant plutôt une approche éditoriale raffinée commune aux applications lifestyle haut de gamme.

La direction visuelle est **Minimaliste** avec une touche **Tactile**. Elle utilise des espaces blancs généreux, des photographies en douceur et une palette sophistiquée monochromatique pour évoquer des sentiments de calme, fiabilité et modernisme. Chaque interaction est conçue pour paraître délibérée et premium, positionnant le shopping de seconde main comme un choix de vie conscient.

---

### Palette de Couleurs

| Nom | Variable | HEX | HSL | Usage |
|---|---|---|---|---|
| **Dusty Rose** | `--dusty-rose` | `#c78283` | `hsla(359, 38%, 65%, 1)` | Couleur principale, identité de marque, highlights CTA |
| **Soft Blush** | `--soft-blush` | `#f3d9dc` | `hsla(353, 52%, 90%, 1)` | Grandes surfaces, fonds clairs, décalages tonals subtils |
| **Pale Oak** | `--pale-oak` | `#d7bea8` | `hsla(28, 37%, 75%, 1)` | Bordures, états désactivés, ornements UI secondaires |
| **Rosy Taupe** | `--rosy-taupe` | `#b49286` | `hsla(16, 23%, 62%, 1)` | Texte placeholder, métadonnées |
| **Mauve Shadow** | `--mauve-shadow` | `#744253` | `hsla(340, 27%, 36%, 1)` | Typographie haute priorité, fond des boutons principaux |

#### Couleurs système Supabase (issues du design.md)

| Rôle | HEX |
|---|---|
| Primary | `#894e4f` |
| Primary Container | `#c78283` |
| On Primary | `#ffffff` |
| Secondary | `#6d5a5c` |
| Secondary Container | `#f3d9dc` |
| Background | `#f9f9f9` |
| Surface | `#f9f9f9` |
| On Surface | `#1a1c1c` |
| Error | `#ba1a1a` |
| Tertiary (accentuation verte) | `#326850` |

#### Dans Flutter (à utiliser dans `ThemeData`)
```dart
const Color dustyRose = Color(0xFFc78283);
const Color softBlush = Color(0xFFf3d9dc);
const Color paleOak = Color(0xFFd7bea8);
const Color rosyTaupe = Color(0xFFb49286);
const Color mauveShadow = Color(0xFF744253);
const Color background = Color(0xFFf9f9f9);
const Color onSurface = Color(0xFF1a1c1c);
```

---

### Typographie

Police principale : **Plus Jakarta Sans**

| Style | Taille | Poids | Interligne | Espacement |
|---|---|---|---|---|
| Titre Large | 28px | 700 | 36px | -0.02em |
| Titre Moyen | 22px | 600 | 28px | -0.01em |
| Titre Large Mobile | 24px | 700 | 32px | — |
| Corps Large | 16px | 400 | 24px | — |
| Corps Moyen | 14px | 400 | 20px | — |
| Label Large | 14px | 600 | 20px | 0.01em |
| Label Petit | 12px | 500 | 16px | 0.04em |

> ⚠️ Aucun emoji dans les textes — utiliser uniquement des icônes Flutter (`Icons.xxx`)

---

### Mise en Page & Espacement

Grille de base : **4px**

| Token | Valeur | Usage |
|---|---|---|
| xs | 4px | Espacement minimal |
| sm | 8px | Espacement interne composants |
| md | 16px | Gouttières entre cartes |
| lg | 24px | Sections |
| xl | 32px | Grands espaces |
| margin mobile | 20px | Marges extérieures |

---

### Élévation & Profondeur

- **Niveau 0 (Fond) :** `#f9f9f9`
- **Niveau 1 (Cartes) :** Fond blanc avec ombre douce 4px blur — `rgba(116, 66, 83, 0.08)`
- **Niveau 2 (Flottant/Actif) :** Boutons d'action flottants avec ombre 12px blur

---

### Formes & Arrondis

| Token | Valeur | Usage |
|---|---|---|
| sm | 4px | Petits éléments |
| md | 12px | Chips, tags |
| lg | 16px | Cartes, champs de saisie, modals |
| xl | 24px | Grandes surfaces |
| full | 9999px | Boutons pilule, avatars |

---

### Composants

#### Boutons
| Type | Fond | Texte | Arrondi |
|---|---|---|---|
| Principal | `#744253` (Mauve Shadow) | `#ffffff` | 16px |
| Secondaire | `#f3d9dc` (Soft Blush) | `#744253` | 16px |
| Fantôme | Transparent | `#c78283` | 16px |

#### Cartes Annonces
- Arrondi : 16px
- Bordure : 1px `#d7bea8` (Pale Oak)
- Ombre : `rgba(116, 66, 83, 0.08)`
- Contenu : Photo + Titre + Prix empilés verticalement (espacement 4px)

#### Barre de Navigation Inférieure
5 onglets :
| Position | Onglet | Icône |
|---|---|---|
| 1 | Accueil | `Icons.home` |
| 2 | Favoris | `Icons.favorite` |
| 3 | **Créer annonce** | Bouton "+" central surélevé, fond `#c78283`, icône blanche |
| 4 | Messages | `Icons.chat_bubble` |
| 5 | Profil | `Icons.person` |

État actif : couleur `#c78283` + indicateur point 4px sous l'icône.

#### Champs de Saisie
- Fond : `#ffffff`
- Bordure normale : 1px `#d7bea8`
- Bordure focus : 1px `#c78283`
- Arrondi : 16px
- Placeholder : `#b49286`

#### Chips & Catégories
- Forme pilule (full rounded)
- Fond : `#f3d9dc`
- Texte : `#744253`

---

### Signalement
- Icône drapeau (`Icons.flag`) en haut à droite de la page détail annonce
- Subtile mais visible
- Ouvre un dialog ou redirige vers le formulaire de signalement

---

*Document mis à jour le 27/06/2026 — Projet Rizen, Alpha Diallo, ESTM Dakar*

---

## 16. Code Flutter — Authentification ✅

### Structure des fichiers créés
```
lib/
├── main.dart                          ✅
├── config/
│   └── supabase_config.dart           ✅
├── theme/
│   └── app_theme.dart                 ✅
├── services/
│   └── auth_service.dart              ✅
├── screens/
│   └── auth/
│       ├── login_screen.dart          ✅
│       └── register_screen.dart       ✅
└── widgets/
    └── common/                        (à remplir)
```

### Points importants

**Trigger inscription mis à jour** — sauvegarde maintenant `telephone` et `adresse` :
```sql
CREATE OR REPLACE FUNCTION public.creer_profil_utilisateur()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profils (id, nom, prenom, email, telephone, adresse, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nom', ''),
    COALESCE(NEW.raw_user_meta_data->>'prenom', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'telephone', ''),
    COALESCE(NEW.raw_user_meta_data->>'adresse', ''),
    'utilisateur'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Gestion erreurs connexion :**
- `Invalid login credentials` → "Email ou mot de passe incorrect"
- `status 500 / Database error granting user` → "Votre compte a été suspendu. Contactez l'administrateur."

**Champs formulaire inscription :**
- Prénom, Nom, Email, Téléphone, Quartier/Adresse, Mot de passe, Confirmation mot de passe

**Dépendances pubspec.yaml :**
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.0
```

**Couleurs Flutter (AppColors) :**
```dart
static const Color dustyRose = Color(0xFFc78283);
static const Color softBlush = Color(0xFFf3d9dc);
static const Color paleOak = Color(0xFFd7bea8);
static const Color rosyTaupe = Color(0xFFb49286);
static const Color mauveShadow = Color(0xFF744253);
static const Color background = Color(0xFFf9f9f9);
static const Color onSurface = Color(0xFF1a1c1c);
static const Color onSurfaceVariant = Color(0xFF524343);
static const Color error = Color(0xFFba1a1a);
static const Color white = Color(0xFFffffff);
```

### Ordre de développement Flutter mis à jour

| Ordre | Écran | Statut |
|---|---|---|
| 1 | Authentification (Inscription / Connexion / Déconnexion) | ✅ |
| 2 | Accueil — Liste des annonces | ❌ |
| 3 | Détail annonce | ❌ |
| 4 | Créer annonce (avec photos) | ❌ |
| 5 | Favoris | ❌ |
| 6 | Messagerie | ❌ |
| 7 | Négociations | ❌ |
| 8 | Profil utilisateur | ❌ |
| 9 | Avis | ❌ |
| 10 | Signalements | ❌ |
| 11 | SuperAdmin | ❌ |

### Comment reprendre dans une nouvelle conversation
1. Donner ce fichier `.md` à Claude
2. Dire : "Je travaille sur Rizen, un marketplace Flutter/Supabase. Lis le fichier .md et continuons avec l'écran d'accueil (liste des annonces)"
3. Claude aura tout le contexte nécessaire

---

*Document mis à jour le 29/06/2026 — Projet Rizen, Alpha Diallo, ESTM Dakar*
