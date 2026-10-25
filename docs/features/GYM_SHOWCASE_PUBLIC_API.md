# API publique — Page vitrine des salles (Cloudflare Pages)

Contexte : une page statique publique (hébergée sur Cloudflare Pages, domaine `team-oustad.com`) va lister les salles de sport et leur fiche détaillée, sans authentification. Toutes les données sont saisies côté app Flutter en mode Owner — dans `lib/screens/admin/admin_home_screen.dart` (vues internes `_GymEditView`, `_GymGalleryView`, `_GymDetailsView` ; les fichiers `admin_create_gym_screen.dart`/`admin_edit_gym_screen.dart`/`admin_gym_opening_hours_screen.dart` existent mais ne sont plus utilisés, à ignorer).

Tout ce qui suit est additif : aucune route existante ne change de comportement, sauf mention explicite.

## 1. Schéma `Gym` — champs à ajouter

```prisma
model Gym {
  // ... champs existants (id, name, address, phone, ...)
  isPublished Boolean  @default(false) // affichage sur la page vitrine publique
  slug        String?  @unique         // ex: "fitness-center-a-1", généré à la création
  description String?  @db.Text        // texte libre affiché sur la fiche publique
}
```

- Pas de coordonnées GPS : la position n'est jamais saisie dans l'app, uniquement l'adresse texte existante (`address`). La page publique affichera une carte en se basant directement sur cette adresse (ex: lien/iframe Google Maps avec l'adresse en requête), pas besoin de latitude/longitude stockées. L'app ne les envoie plus du tout (retiré de `createGym`/`updateGym` côté client).
- `isPublished` : nouveau champ accepté en plus sur `PUT /gyms/{id}` (optionnel, booléen). Déjà câblé côté app (`ApiService.updateGym` envoie `isPublished`, toggle "Publier sur le site vitrine" dans l'écran d'édition). Même règle de permission que le reste de cette route (owner : toutes les salles, admin : uniquement sa salle). Défaut `false` à la création — une salle n'apparaît jamais publiquement sans action explicite. La réponse de `PUT /gyms/{id}` doit renvoyer `isPublished` dans l'objet `gym`.
- `slug` : généré automatiquement à la création (`POST /gyms`) à partir du nom en kebab-case + suffixe id pour garantir l'unicité (ex: "Fitness Center A" → `fitness-center-a-1`). Ne change pas automatiquement si le nom est modifié ensuite (stabilité des URLs publiques). Accepter en plus un override manuel optionnel via `PUT /gyms/{id}` (`slug: string`) si l'owner veut un slug plus propre.
- `description` : texte libre optionnel (prévoir ~500 caractères, c'est la limite côté app), accepté sur `POST /gyms` et `PUT /gyms/{id}` (déjà câblé côté app : champ "Description" dans `_GymEditView`, `ApiService.createGym`/`updateGym` envoient `description`). Même règle de permission que le reste de la route. Pas de sanitization HTML particulière attendue côté serveur au-delà de ce qui est déjà fait pour les autres champs texte (`name`, `address`) — la page publique l'affiche en texte brut.

## 2. Galerie photo (nouvelle table `GymPhoto`)

Aujourd'hui une salle n'a qu'une seule image (`PUT/GET/DELETE /gyms/{id}/image`, base64). On garde cet endpoint tel quel (déjà utilisé ailleurs dans l'app) et on ajoute une galerie à côté, même convention de stockage (base64) :

```prisma
model GymPhoto {
  id        Int      @id @default(autoincrement())
  gymId     Int
  gym       Gym      @relation(fields: [gymId], references: [id], onDelete: Cascade)
  imageData String   // base64, même format que l'image unique existante
  position  Int      @default(0)
  isCover   Boolean  @default(false)
  createdAt DateTime @default(now())
}
```

### Routes authentifiées (gestion depuis l'app, même permission que le reste de `/gyms/{id}/*` : owner toutes salles, admin sa salle uniquement)

Déjà câblées côté app (`ApiService.addGymPhoto`, `getGymPhotos`, `deleteGymPhoto`, `reorderGymPhotos`, `setGymPhotoCover`, `gymPhotoImageUri` dans `lib/core/services/api_service.dart`), et un écran galerie complet (`_GymGalleryView` dans `admin_home_screen.dart`) — il attend exactement ces formes de réponse :

- `POST /gyms/{id}/photos` — body `{ "imageData": "data:image/jpeg;base64,..." }` → crée une photo, retourne `{ "photo": { "id": 5, "position": 2, "isCover": false } }`. `position` = max existant + 1.
- `GET /gyms/{id}/photos` — liste des métadonnées (sans les données binaires, pour l'écran galerie de l'app) → `{ "photos": [{ "id": 5, "position": 0, "isCover": true }, ...] }`.
- `GET /gyms/{id}/photos/{photoId}/image` — binaire (même logique de content-type que `GET /gyms/{id}/image`), authentifié.
- `DELETE /gyms/{id}/photos/{photoId}`.
- `PUT /gyms/{id}/photos/reorder` — body `{ "order": [5, 2, 7] }` (liste d'ids dans le nouvel ordre) → réassigne `position`.
- `PUT /gyms/{id}/photos/{photoId}/cover` — met `isCover=true` sur celle-ci et `false` sur les autres photos de la même salle.

Pas de limite stricte côté serveur à poser, mais une recommandation côté app (ex: 10 photos max) suffit — pas besoin de contrainte DB.

## 3. Compteur de membres affiché publiquement

Jamais le chiffre exact publiquement. Calculer `memberCountDisplay` (string) à partir du vrai compte (`_count.users`, en excluant les rôles `admin`/`owner` — on ne compte que les membres) :

- `count < 10` → exact, ex: `"7"`
- `10 <= count < 100` → arrondi à la dizaine inférieure + `"+"`, ex: 47 → `"40+"`
- `count >= 100` → arrondi à la cinquantaine inférieure + `"+"`, ex: 247 → `"200+"`

Ce champ est calculé à la volée dans les routes publiques ci-dessous, pas stocké en base.

## 4. Équipe affichée publiquement

Réutiliser les users déjà liés à la salle (relation existante, visible aujourd'hui dans `GET /gyms/{id}` → `users[]`). Pour la page publique : ne garder que `role IN ('admin', 'owner')` (jamais les membres), et exposer uniquement `id`, `fullName`, `role`, plus une URL de photo (voir route publique ci-dessous) — jamais l'email.

## 5. Nouvelles routes publiques (aucune authentification, lecture seule)

Toutes sous un préfixe `/public` dédié — ne jamais réutiliser les routes authentifiées existantes en les rendant publiques, pour ne pas changer leur contrat actuel. CORS ouvert (`Access-Control-Allow-Origin: *`) puisque c'est consommé depuis `team-oustad.com` en fetch côté client. Un cache HTTP court (ex: `Cache-Control: public, max-age=300`) est recommandé mais pas bloquant.

### `GET /public/gyms`

Liste des salles avec `isPublished = true` uniquement.

```json
{
  "gyms": [
    {
      "id": 1,
      "slug": "fitness-center-a-1",
      "name": "Fitness Center A",
      "address": "123 Main St",
      "phone": "+1234567890",
      "memberCountDisplay": "250+",
      "coverPhotoUrl": "https://api.team-oustad.com/public/gyms/1/photos/5/image"
    }
  ]
}
```

`coverPhotoUrl` : la photo avec `isCover=true` de cette salle, ou `null` si aucune photo.

### `GET /public/gyms/{slugOrId}`

Lookup par `slug` (fallback sur l'id numérique si le paramètre est un entier). 404 si la salle n'existe pas ou si `isPublished = false`.

```json
{
  "gym": {
    "id": 1,
    "slug": "fitness-center-a-1",
    "name": "Fitness Center A",
    "address": "123 Main St",
    "phone": "+1234567890",
    "memberCountDisplay": "250+",
    "description": "Salle de sport moderne avec équipements dernier cri...",
    "openingHours": [
      { "dayOfWeek": 1, "openTime": "09:00", "closeTime": "22:00", "isClosed": false }
    ],
    "photos": [
      { "id": 5, "url": "https://api.team-oustad.com/public/gyms/1/photos/5/image", "isCover": true },
      { "id": 6, "url": "https://api.team-oustad.com/public/gyms/1/photos/6/image", "isCover": false }
    ],
    "team": [
      {
        "id": 10,
        "fullName": "Jean Dupont",
        "role": "admin",
        "photoUrl": "https://api.team-oustad.com/public/gyms/1/team/10/image"
      }
    ]
  }
}
```

### `GET /public/gyms/{gymId}/photos/{photoId}/image`

Binaire (même logique de sniffing de content-type que l'endpoint authentifié équivalent). Vérifie que la photo appartient bien à `gymId` **et** que `gym.isPublished = true`, sinon 404. Comme ça une salle non publiée ne fuite jamais ses photos même si quelqu'un deviner un id.

### `GET /public/gyms/{gymId}/team/{userId}/image`

Binaire, même source de données que l'actuel `GET /users/{id}/profile-image`. Vérifie que `userId` appartient bien à `gymId`, que son rôle est `admin` ou `owner`, et que `gym.isPublished = true`, sinon 404.

## 6. Permissions — récapitulatif

| Route | Auth | Qui |
|---|---|---|
| `POST/GET/DELETE /gyms/{id}/photos*` | Bearer | owner (toutes salles), admin (sa salle) — identique aux règles déjà appliquées sur `/gyms/{id}` |
| `PUT /gyms/{id}` (+ `isPublished`, `slug`, `description`) | Bearer | idem, pas de nouvelle règle |
| `GET /public/*` | Aucune | public, lecture seule, jamais de données sensibles (pas d'email, pas de compte exact, pas de salle non publiée) |

## 7. Checklist pour claude serveur

- [ ] Migration Prisma : `Gym.isPublished`, `Gym.slug`, `Gym.description` + table `GymPhoto`
- [ ] Génération de `slug` à la création (kebab-case + id, unique)
- [ ] `isPublished` acceptable sur `PUT /gyms/{id}`, défaut `false` à la création
- [ ] Endpoints galerie photo authentifiés (section 2)
- [ ] Endpoints publics `/public/gyms`, `/public/gyms/{slugOrId}`, `/public/gyms/{gymId}/photos/{photoId}/image`, `/public/gyms/{gymId}/team/{userId}/image` (section 5), CORS ouvert
- [ ] Calcul `memberCountDisplay` côté serveur, jamais le chiffre exact publiquement (section 3)
- [ ] Mettre à jour `swagger.yml` (nouveau schéma `Gym`, nouvelles routes `/gyms/{id}/photos*` et `/public/*`)

## 8. Contenu éditable (CMS vitrine)

Depuis l'app, on édite des **pages composées de sections** : la page d'accueil du site (owner) et la fiche de chaque salle (owner, admin de la salle). On peut ajouter, modifier, réordonner, masquer et supprimer des sections. Éditeur : `ShowcaseEditorScreen` (Gestion globale → « Site vitrine », fiche salle → « Contenu de la page vitrine », Gestion → « Page vitrine de ma salle » pour un admin). Modèle client : `lib/core/models/showcase_page_model.dart`.

### Format d'une page

```json
{
  "hero": { "eyebrow": "VITRINE TEAM OUSTAD", "tagline": "Choisis ta salle. Dépasse tes limites." },
  "sections": [
    { "id": "marquee", "type": "marquee", "visible": true, "data": { "words": ["MUSCULATION", "CARDIO"] } },
    { "id": "gyms", "type": "gyms", "visible": true },
    { "id": "s1k9x", "type": "markdown", "visible": false, "data": { "title": "Nouveau", "body": "**Ouverture** le 1er mars" } }
  ]
}
```

- `hero` : page d'accueil uniquement (absent pour une salle).
- L'**ordre du tableau** est l'ordre d'affichage. `visible: false` = section conservée mais non affichée.
- `id` : chaîne générée par l'app, unique dans la page. Le serveur la stocke telle quelle.

Types **de contenu** (avec `data`) :

| `type` | `data` |
|---|---|
| `markdown` | `title`, `body` (markdown) |
| `feature` | `eyebrow`, `title`, `body`, `points: string[]`, `icon`, `tag` |
| `testimonials` | `eyebrow`, `title`, `items: [{ name, meta, quote }]` |
| `marquee` | `words: string[]` |
| `categories` | `items: [{ label, icon }]` |
| `cta` | `eyebrow`, `text`, `buttonLabel`, `url` |

`icon` est une clé parmi `fitness, fire, groups, run, food, target, heart, bolt, timer, star, zen, trophy, pool, bike` (inconnue → icône par défaut côté app).

Types **intégrés** (sans `data`, contenu fourni par les autres endpoints ; déplaçables/masquables, pas supprimables) :
- accueil : `gyms` (liste des salles), `promos` (bannières réseau) ;
- salle : `gymAbout` (`Gym.description`), `gymPromos`, `gymInfo` (adresse, contact, carte), `gymHours`, `gymTeam`, `gymSubscriptions`.

L'app ignore les types inconnus et rajoute en fin de page un type intégré absent : le serveur n'a pas à connaître la liste exhaustive, mais doit **conserver** ce qu'il reçoit.

### Stockage

```prisma
model ShowcasePage {
  key       String   @id                // "home" ou "gym:<id>"
  gymId     Int?     @unique
  gym       Gym?     @relation(fields: [gymId], references: [id], onDelete: Cascade)
  content   Json                        // { hero?, sections } validé puis stocké tel quel
  updatedAt DateTime @updatedAt
  updatedBy Int?                        // user id, pour l'audit
}
```

La clé texte garantit une seule page d'accueil sans dépendre d'un `NULL` unique.

La description de salle reste `Gym.description` (éditée dans la fiche salle). Le CMS ne la duplique pas : la section `gymAbout` l'affiche.

### Routes

| Route | Auth | Qui |
|---|---|---|
| `GET /showcase/home` | Bearer | owner |
| `PUT /showcase/home` | Bearer | owner |
| `GET /gyms/{gymId}/showcase` | Bearer | owner (toutes salles), admin **de cette salle** |
| `PUT /gyms/{gymId}/showcase` | Bearer | idem |
| `GET /public/showcase/home` | aucune | public |
| `GET /public/gyms/{slugOrId}` | aucune | public — inclut `gym.showcase` = la page de la salle |

- `GET` (auth et public) : **200** avec la page, ou `{}` si rien n'a été enregistré (l'app affiche alors le contenu par défaut). Ne pas renvoyer 404 pour « pas encore de page ».
- `PUT` : body = page complète, remplace l'existant (upsert). Réponse 200 ou 204.
- `GET /public/gyms/{slugOrId}` : n'inclure `showcase` que pour une salle publiée (règle existante). Les sections `visible: false` peuvent être filtrées côté serveur.
- `Cache-Control: max-age=300` sur les routes publiques : une modification met jusqu'à 5 min à apparaître (l'app l'indique après sauvegarde).

### Validation `PUT` (400 sinon)

- `sections` : tableau, ≤ 40 éléments ; chaque élément a `id` (string ≤ 40), `type` (string ≤ 40), `visible` (bool) et `data` objet optionnel.
- Taille totale du body ≤ 100 Ko ; toute chaîne ≤ 5 000 caractères ; tableaux internes (`points`, `words`, `items`) ≤ 20.
- `hero` accepté uniquement sur `/showcase/home`.
- `url` des `cta` : schéma `https://` (ou `http://`) uniquement — refuser `javascript:`, `data:`, etc.
- Ne pas exécuter ni nettoyer de HTML : l'app rend le markdown avec `flutter_markdown`, sans HTML brut. Les liens markdown ne s'ouvrent qu'en externe.

### Ancien format

Avant les sections, `GET /gyms/{gymId}/showcase` était un objet plat (`description`, `amenities`, `schedule`, `pricing`, `team`). L'app sait encore le lire (converti en sections `markdown`), mais le serveur doit implémenter directement le format ci-dessus.

### Côté serveur (fait, `team_fitness_server`)

- [x] Migration `20261025000000_add_showcase_pages` : table `ShowcasePage` + colonne `Gym.description`
- [x] `GET/PUT /showcase/home` (owner) et `GET/PUT /gyms/{gymId}/showcase` (owner avec `canManageGyms`, admin de la salle), 403 sinon
- [x] `GET` renvoie `{}` (200) tant que rien n'est enregistré
- [x] Validation du body `PUT` (`utils/showcasePages.js`)
- [x] `GET /public/showcase/home` + `gym.description` et `gym.showcase` dans `GET /public/gyms/{slugOrId}` (sections masquées exclues)
- [x] `PUT /gyms/{id}` accepte `description`
- [x] `swagger.yml` serveur mis à jour
