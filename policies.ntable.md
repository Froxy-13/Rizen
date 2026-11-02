# Rizen — Base de données Supabase : Tables & Policies RLS

> URL : `https://wzujxtmjaojdqipqfkwn.supabase.co`  
> Exporté le : 2026-11-02

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
| date_publication | timestamptz | YES | now() |
| statut | varchar | YES | `'active'` |
| utilisateur_id | uuid → auth.users.id | NO | — |
| categorie_id | integer → categories.id | YES | — |
| ville | varchar | YES | — |
| quartier | varchar | YES | — |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() |

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
| Colonne | Type | Nullable |
|---|---|---|
| id | integer (PK, auto) | NO |
| nom | varchar | NO |
| description | text | YES |
| created_at | timestamptz | YES |

---

### `conversation_participants`
| Colonne | Type |
|---|---|
| conversation_id | integer → conversations.id |
| utilisateur_id | uuid → auth.users.id |

---

### `conversations`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| date_creation | timestamptz | now() |
| statut | varchar | `'active'` |
| annonce_id | integer | — |
| created_at | timestamptz | now() |

---

### `favoris`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| utilisateur_id | uuid | — |
| annonce_id | integer | — |
| date_ajout | timestamptz | now() |

---

### `images_annonce`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| annonce_id | integer → annonces.id | — |
| url_image | text | — |
| ordre | integer | 0 |
| created_at | timestamptz | now() |

---

### `messages`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| conversation_id | integer | — |
| sender_id | uuid | — |
| contenu | text | — |
| date_envoi | timestamptz | now() |
| lu | boolean | false |
| type | varchar | `'texte'` |
| negociation_id | integer | — |
| transaction_id | integer | — |
| created_at | timestamptz | now() |

---

### `negociations`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| annonce_id | integer | — |
| acheteur_id | uuid | — |
| vendeur_id | uuid | — |
| prix_propose | numeric | — |
| date_proposition | timestamptz | now() |
| statut | varchar | `'en_attente'` |
| conversation_id | integer | — |
| message | text | — |
| created_at | timestamptz | now() |

---

### `notifications`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| utilisateur_id | uuid | — |
| titre | varchar | — |
| message | text | — |
| type | varchar | — |
| lu | boolean | false |
| date_notification | timestamptz | now() |
| created_at | timestamptz | now() |

---

### `paiements`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| transaction_id | integer | — |
| montant | numeric | — |
| methode | varchar | — |
| reference | varchar | — |
| date_paiement | timestamptz | now() |
| statut | varchar | `'en_attente'` |
| created_at | timestamptz | now() |

---

### `profils`
| Colonne | Type | Défaut |
|---|---|---|
| id | uuid (PK = auth.users.id) | — |
| nom | varchar | NO |
| prenom | varchar | NO |
| email | varchar | NO |
| telephone | varchar | YES |
| photo | text | YES |
| adresse | text | YES |
| date_inscription | timestamptz | now() |
| statut | varchar | `'actif'` |
| role | varchar | `'utilisateur'` |
| created_at | timestamptz | now() |
| updated_at | timestamptz | now() |

> ⚠️ `profils` n'a PAS de colonne `ville` — utiliser `adresse` pour la localisation.

---

### `signalements`
| Colonne | Type | Défaut |
|---|---|---|
| id | integer (PK, auto) | — |
| annonce_id | integer | — |
| utilisateur_id | uuid | — |
| raison | varchar | — |
| description | text | — |
| date_signalement | timestamptz | now() |
| statut | varchar | `'en_attente'` |
| traite_par | uuid | — |
| created_at | timestamptz | now() |

---

### `transactions`
(colonnes connues via policies RLS)  
`id`, `acheteur_id` (uuid), `vendeur_id` (uuid), `annonce_id` (probable)

---

## Relations clés

```
auth.users.id
  ├── profils.id (1:1)
  ├── annonces.utilisateur_id (1:N)
  ├── avis.vendeur_id (1:N)
  ├── avis.acheteur_id (1:N)
  ├── conversation_participants.utilisateur_id (N:N)
  ├── favoris.utilisateur_id (1:N)
  └── transactions.acheteur_id / vendeur_id

annonces.id
  ├── images_annonce.annonce_id (1:N)
  ├── favoris.annonce_id (1:N)
  ├── negociations.annonce_id (1:N)
  └── conversations.annonce_id (1:N)

categories.id
  └── annonces.categorie_id (1:N)
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

### `avis`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire avis | public | SELECT | `true` (tout le monde) |
| Créer avis | public | INSERT | `auth.uid() = acheteur_id` |
| Supprimer avis | public | DELETE | `auth.uid() = acheteur_id` OU `est_superadmin()` |

### `categories`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire categories | public | SELECT | `true` (tout le monde) |
| SuperAdmin gérer | public/authenticated | ALL | `est_superadmin()` |

### `images_annonce`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire images | public | SELECT | `true` (tout le monde) |
| Gérer images | public | ALL | propriétaire de l'annonce OU `est_superadmin()` |

### `profils`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire profil | public | SELECT | `true` (tout le monde) |
| Modifier profil | public | UPDATE | `auth.uid() = id` (ne peut pas changer statut/rôle) |
| SuperAdmin modifier | public | UPDATE | `est_superadmin()` |
| SuperAdmin supprimer | public | DELETE | `est_superadmin()` |

### `favoris`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire favoris | public | SELECT | `auth.uid() = utilisateur_id` |
| Ajouter favori | public | INSERT | `auth.uid() = utilisateur_id` |
| Supprimer favori | public | DELETE | `auth.uid() = utilisateur_id` |

### `conversations` & `messages`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire conversations | public | SELECT | utilisateur est participant |
| Créer conversation | authenticated | INSERT | `auth.uid() IS NOT NULL` |
| Lire messages | public | SELECT | utilisateur est participant OU superadmin |
| Envoyer message | public | INSERT | `auth.uid() = sender_id` |
| Marquer lu | public | UPDATE | utilisateur est participant |

### `negociations`
| Policy | Rôle | Opération | Condition |
|---|---|---|---|
| Lire | public | SELECT | acheteur OU vendeur de l'annonce OU superadmin |
| Créer | public | INSERT | `auth.uid() = acheteur_id` |
| Modifier | public | UPDATE | acheteur OU vendeur de l'annonce |

### `transactions` & `paiements`
Lecture/modification : acheteur OU vendeur OU superadmin  
Création : authenticated uniquement

### `signalements`
Lecture : propriétaire OU superadmin  
Création : `auth.uid() = utilisateur_id`  
Traitement : superadmin uniquement

---

## Fonctions SQL custom
- `est_superadmin()` — retourne `true` si l'utilisateur connecté a le rôle superadmin
- `est_participant_conversation(conversation_id)` — vérifie si l'user est dans une conversation

## Accès sans authentification (anon key)
Les tables lisibles sans être connecté :
- `annonces` (statut = 'active' seulement)
- `categories` (toutes)
- `images_annonce` (toutes)
- `profils` (tous)
- `avis` (tous)
