# Rizen — Base de données Supabase : Tables & Policies RLS

> URL : `https://wzujxtmjaojdqipqfkwn.supabase.co`  
> Dernière mise à jour : 2026-11-03 (migration_v2.sql appliquée + accusé de lecture messages)

---

## Tables & Colonnes

### `annonces`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | nextval |
| titre | varchar | NO | — |
| description | text | NO | — |
| prix_initial | numeric | NO | — |
| prix_actuel | numeric | NO | — |
| etat | varchar | YES | NULL — valeurs : `neuf` / `tres_bon` / `bon` / `correct` |
| vues | integer | NO | `0` |
| slug | varchar | YES | NULL |
| boost_expires_at | timestamptz | YES | NULL |
| statut | varchar | YES | `'active'` — valeurs : `active` / `vendue` / `suspendue` |
| utilisateur_id | uuid → auth.users.id | NO | — |
| categorie_id | integer → categories.id | YES | — |
| sous_categorie_id | integer → sous_categories.id | YES | NULL |
| ville | varchar | YES | — |
| quartier | varchar | YES | — |
| date_publication | timestamptz | YES | now() |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() — mis à jour automatiquement par trigger |

---

### `annonce_attributs`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| cle | varchar | NO | — ex : "Couleur", "Taille", "Marque" |
| valeur | varchar | NO | — ex : "Noir", "XL", "Samsung" |
| created_at | timestamptz | YES | now() |

---

### `annonce_vues`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| utilisateur_id | uuid → auth.users.id | YES | NULL — si visiteur anonyme |
| ip_hash | varchar | YES | NULL — hash IP pour anonymes |
| vu_le | timestamptz | YES | now() |

> Index : `idx_annonce_vues_annonce` sur `annonce_id`

---

### `avis`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| acheteur_id | uuid | NO | — |
| vendeur_id | uuid | NO | — |
| note | integer | NO | — |
| commentaire | text | YES | — |
| date_avis | timestamptz | YES | now() |
| transaction_id | integer | YES | — |
| emetteur | varchar | YES | `'acheteur'` |
| created_at | timestamptz | YES | now() |

---

### `categories`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| nom | varchar | NO | — |
| description | text | YES | — |
| created_at | timestamptz | YES | now() |

---

### `conversation_participants`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| conversation_id | integer → conversations.id | NO | — |
| utilisateur_id | uuid → auth.users.id | NO | — |

> Clé primaire composite : `(conversation_id, utilisateur_id)`

---

### `conversations`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| statut | varchar | YES | `'active'` |
| date_creation | timestamptz | YES | now() |
| created_at | timestamptz | YES | now() |

---

### `favoris`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| utilisateur_id | uuid → auth.users.id | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| date_ajout | timestamptz | YES | now() |

---

### `images_annonce`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| url_image | text | NO | — |
| ordre | integer | YES | `0` |
| created_at | timestamptz | YES | now() |

> Storage bucket : **`annonces-images`** (public, 50 MB max)

---

### `messages`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| conversation_id | integer → conversations.id | NO | — |
| sender_id | uuid → auth.users.id | NO | — |
| contenu | text | NO | — |
| date_envoi | timestamptz | YES | now() |
| lu | boolean | NO | `false` — accusé de lecture |
| type | varchar | YES | `'texte'` — valeurs : `texte` / `negociation` |
| negociation_id | integer → negociations.id | YES | NULL |
| transaction_id | integer → transactions.id | YES | NULL |
| created_at | timestamptz | YES | now() |

> `lu` passe à `true` quand le destinataire ouvre la conversation. Seul le destinataire peut modifier cette colonne (policy RLS `WITH CHECK (lu = TRUE)`). Utilisé pour les accusés de lecture (double coche grise → orange) et le comptage des non-lus dans la navbar.

---

### `negociations`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| acheteur_id | uuid → auth.users.id | NO | — |
| vendeur_id | uuid → auth.users.id | NO | — |
| prix_propose | numeric | NO | — |
| statut | varchar | YES | `'en_attente'` — valeurs : `en_attente` / `acceptee` / `refusee` / `annulee` |
| conversation_id | integer → conversations.id | YES | — |
| message | text | YES | NULL — message optionnel joint à l'offre |
| date_proposition | timestamptz | YES | now() |
| created_at | timestamptz | YES | now() |

---

### `notifications`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| utilisateur_id | uuid → auth.users.id | NO | — |
| titre | varchar | NO | — |
| message | text | NO | — |
| type | varchar | NO | — |
| lu | boolean | NO | `false` |
| date_notification | timestamptz | YES | now() |
| created_at | timestamptz | YES | now() |

---

### `paiements`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| transaction_id | integer → transactions.id | NO | — |
| montant | numeric | NO | — |
| methode | varchar | NO | — |
| reference | varchar | YES | — |
| date_paiement | timestamptz | YES | now() |
| statut | varchar | YES | `'en_attente'` |
| created_at | timestamptz | YES | now() |

---

### `profils`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | uuid (PK = auth.users.id) | NO | — |
| nom | varchar | NO | — |
| prenom | varchar | NO | — |
| email | varchar | NO | — |
| telephone | varchar | YES | — |
| photo | text | YES | — |
| adresse | text | YES | — adresse texte libre |
| ville | varchar | YES | — ville principale (séparée d'adresse) |
| bio | text | YES | — présentation courte du vendeur |
| certifie | boolean | NO | `false` — badge vendeur certifié (validé par admin) |
| note_moyenne | numeric(3,2) | YES | NULL — cache mis à jour par trigger après chaque avis |
| nombre_avis | integer | NO | `0` — cache mis à jour par trigger |
| nombre_ventes | integer | NO | `0` — incrémenté par trigger quand annonce → vendue |
| statut | varchar | YES | `'actif'` |
| role | varchar | YES | `'utilisateur'` |
| date_inscription | timestamptz | YES | now() |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() — mis à jour automatiquement par trigger |

> Storage bucket : **`profils-photos`** (public, 50 MB max)  
> ⚠️ La colonne `certifie` ne peut être mise à `true` que par un superadmin.

---

### `signalements`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| annonce_id | integer → annonces.id | NO | — |
| utilisateur_id | uuid → auth.users.id | NO | — |
| raison | varchar | NO | — |
| description | text | YES | — |
| date_signalement | timestamptz | YES | now() |
| statut | varchar | YES | `'en_attente'` |
| traite_par | uuid → auth.users.id | YES | NULL |
| created_at | timestamptz | YES | now() |

---

### `sous_categories`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| categorie_id | integer → categories.id | NO | — |
| nom | varchar | NO | — |
| created_at | timestamptz | YES | now() |

---

### `transactions`
| Colonne | Type | Nullable | Défaut |
|---|---|---|---|
| id | integer (PK, auto) | NO | — |
| acheteur_id | uuid → auth.users.id | NO | — |
| vendeur_id | uuid → auth.users.id | NO | — |
| annonce_id | integer → annonces.id | YES | — |
| montant | numeric | YES | — |
| statut | varchar | YES | `'en_attente'` |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() |

---

## Relations clés

```
auth.users.id
  ├── profils.id (1:1)
  ├── annonces.utilisateur_id (1:N)
  ├── avis.vendeur_id (1:N)
  ├── avis.acheteur_id (1:N)
  ├── conversation_participants.utilisateur_id (N:N via conversations)
  ├── favoris.utilisateur_id (1:N)
  ├── annonce_vues.utilisateur_id (1:N)
  ├── negociations.acheteur_id / vendeur_id (1:N)
  └── transactions.acheteur_id / vendeur_id (1:N)

annonces.id
  ├── images_annonce.annonce_id (1:N)
  ├── annonce_attributs.annonce_id (1:N)
  ├── annonce_vues.annonce_id (1:N)
  ├── favoris.annonce_id (1:N)
  ├── negociations.annonce_id (1:N)
  └── conversations.annonce_id (1:N)

conversations.id
  ├── conversation_participants.conversation_id (1:N)
  ├── messages.conversation_id (1:N)
  └── negociations.conversation_id (1:N)

categories.id
  ├── annonces.categorie_id (1:N)
  └── sous_categories.categorie_id (1:N)

sous_categories.id
  └── annonces.sous_categorie_id (1:N)
```

---

## Policies RLS

### `annonces`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire annonces | public | SELECT | `statut = 'active'` OU `auth.uid() = utilisateur_id` OU `est_superadmin()` |
| Créer annonce | public | INSERT | `auth.uid() = utilisateur_id` |
| Modifier annonce | public | UPDATE | `auth.uid() = utilisateur_id` OU `est_superadmin()` |
| Supprimer annonce | public | DELETE | `auth.uid() = utilisateur_id` OU `est_superadmin()` |
| SuperAdmin gérer | authenticated | ALL | `est_superadmin()` |

### `annonce_attributs`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire attributs | public | SELECT | `true` (tout le monde) |
| Gérer attributs | public | ALL | propriétaire de l'annonce OU `est_superadmin()` |

### `annonce_vues`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Insérer vue | public | INSERT | `true` (tout le monde) |
| Lire vues (propriétaire) | public | SELECT | propriétaire de l'annonce OU `est_superadmin()` |

### `avis`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire avis | public | SELECT | `true` (tout le monde) |
| Créer avis | public | INSERT | `auth.uid() = acheteur_id` |
| Supprimer avis | public | DELETE | `auth.uid() = acheteur_id` OU `est_superadmin()` |

### `categories` & `sous_categories`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire categories | public | SELECT | `true` (tout le monde) |
| SuperAdmin gérer | authenticated | ALL | `est_superadmin()` |

### `conversations` & `conversation_participants`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire conversations | public | SELECT | utilisateur est participant |
| Créer conversation | authenticated | INSERT | `auth.uid() IS NOT NULL` |

### `favoris`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire favoris | public | SELECT | `auth.uid() = utilisateur_id` |
| Ajouter favori | public | INSERT | `auth.uid() = utilisateur_id` |
| Supprimer favori | public | DELETE | `auth.uid() = utilisateur_id` |

### `images_annonce`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire images | public | SELECT | `true` (tout le monde) |
| Gérer images | public | ALL | propriétaire de l'annonce OU `est_superadmin()` |

### `messages`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire messages | public | SELECT | utilisateur est participant OU superadmin |
| Envoyer message | public | INSERT | `auth.uid() = sender_id` |
| Marquer message lu | authenticated | UPDATE | `sender_id != auth.uid()` ET utilisateur est participant — `WITH CHECK (lu = TRUE)` |

> La policy UPDATE n'autorise que `lu = TRUE` : le destinataire ne peut pas modifier le contenu ni d'autres champs.

### `negociations`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire | public | SELECT | acheteur OU vendeur de l'annonce OU superadmin |
| Créer | public | INSERT | `auth.uid() = acheteur_id` |
| Modifier | public | UPDATE | acheteur OU vendeur de l'annonce |

### `profils`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire profil | public | SELECT | `true` (tout le monde) |
| Modifier profil | public | UPDATE | `auth.uid() = id` (ne peut pas changer `statut` / `role` / `certifie`) |
| SuperAdmin modifier | public | UPDATE | `est_superadmin()` |
| SuperAdmin supprimer | public | DELETE | `est_superadmin()` |

### `signalements`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire | public | SELECT | `auth.uid() = utilisateur_id` OU `est_superadmin()` |
| Créer | public | INSERT | `auth.uid() = utilisateur_id` |
| Traiter | public | UPDATE | `est_superadmin()` |

### `transactions` & `paiements`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire | public | SELECT | acheteur OU vendeur OU superadmin |
| Créer | authenticated | INSERT | `auth.uid() IS NOT NULL` |
| Modifier | public | UPDATE | acheteur OU vendeur OU superadmin |

---

## Fonctions SQL custom

| Fonction | Signature | Description |
|---|---|---|
| `est_superadmin()` | `() → boolean` | Retourne `true` si l'utilisateur connecté a le rôle `superadmin` |
| `est_participant_conversation` | `(conversation_id int) → boolean` | Vérifie si l'user courant est dans `conversation_participants` |
| `creer_conversation` | `(p_annonce_id int, p_vendeur_id uuid) → int` | Crée ou retourne la conversation existante acheteur ↔ vendeur pour une annonce. Appelée via `supabase.rpc('creer_conversation', {...})` |
| `incrementer_vues` | `(p_annonce_id int) → void` | Incrémente `annonces.vues` + enregistre dans `annonce_vues` (dédupliqué par user sur 24h). Appelée via `supabase.rpc('incrementer_vues', {...})` |
| `maj_note_vendeur` | trigger function | Recalcule `profils.note_moyenne` et `profils.nombre_avis` après INSERT/DELETE sur `avis` |
| `maj_nombre_ventes` | trigger function | Incrémente/décrémente `profils.nombre_ventes` quand `annonces.statut` change vers/depuis `vendue` |
| `set_updated_at` | trigger function | Met à jour `updated_at = now()` avant chaque UPDATE sur `annonces` et `profils` |

---

## Triggers

| Trigger | Table | Événement | Fonction |
|---|---|---|---|
| `trg_maj_note_vendeur_insert` | `avis` | AFTER INSERT | `maj_note_vendeur()` |
| `trg_maj_note_vendeur_delete` | `avis` | AFTER DELETE | `maj_note_vendeur()` |
| `trg_maj_nombre_ventes` | `annonces` | AFTER UPDATE OF statut | `maj_nombre_ventes()` |
| `trg_annonces_updated_at` | `annonces` | BEFORE UPDATE | `set_updated_at()` |
| `trg_profils_updated_at` | `profils` | BEFORE UPDATE | `set_updated_at()` |

---

## Realtime activé

Tables avec Supabase Realtime activé (utilisées dans le client) :

| Table | Événements écoutés | Usage |
|---|---|---|
| `messages` | INSERT | Nouveau message dans la conversation ouverte — ajout direct sans refetch |
| `messages` | INSERT (global) | Nouveau message dans une conv non-ouverte — incrémente le badge non-lu + met à jour le preview sidebar |
| `messages` | UPDATE | Passage de `lu` à `true` — ticks passent de gris à orange côté expéditeur |
| `negociations` | UPDATE | Changement de `statut` (acceptée/refusée) — mise à jour des cartes de négociation en temps réel |

> Pour que le Realtime fonctionne, les tables doivent avoir la réplication activée dans le dashboard Supabase : **Database → Replication → Tables**.

---

## Storage buckets

| Bucket | Visibilité | Usage |
|---|---|---|
| `profils-photos` | Public | Photos de profil utilisateurs |
| `annonces-images` | Public | Photos des annonces (uploadées depuis `/annonces/creer`) |

---

## Accès sans authentification (anon key)

Tables lisibles sans être connecté :
- `annonces` (statut = `active` seulement)
- `categories` (toutes)
- `sous_categories` (toutes)
- `images_annonce` (toutes)
- `annonce_attributs` (toutes)
- `profils` (tous)
- `avis` (tous)
