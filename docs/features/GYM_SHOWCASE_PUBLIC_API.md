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
