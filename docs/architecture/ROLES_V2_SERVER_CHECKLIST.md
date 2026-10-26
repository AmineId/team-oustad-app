# Checklist pour Claude serveur — Rôles V2 (Owner / Manager / Coach / Member)

> **Contexte uniquement — ne lancer aucune modification.** Ce document fixe le
> contrat attendu par l'app Flutter avant le début du chantier. Merci de relire,
> signaler les objections / contraintes Prisma, et proposer les noms définitifs
> (routes, champs) avant implémentation. Le client ne démarre qu'une fois ce
> contrat validé et le `swagger.yml` mis à jour.

## 1. Rôles

| Rôle | Ancien nom | Portée | Créé par |
|---|---|---|---|
| `owner` | owner | toutes les salles (super admin) | — |
| `manager` | **admin** | **une seule salle** (`gymId`) | owner |
| `coach` | — (nouveau) | **une ou plusieurs salles** | owner uniquement |
| `member` | member | sa salle | manager / owner |

- [ ] Renommer `admin` → `manager` partout (enum Prisma, données existantes, JWT `role`/`type`, réponses `/auth/login` `userType`, `/auth/me`).
- [ ] Période de transition : accepter `admin` en entrée comme alias de `manager` (anciens clients encore en prod), mais toujours **renvoyer** `manager`.
- [ ] `/users/create-admin` → `/users/create-manager` (garder l'ancienne route en alias le temps de la transition).
- [ ] Nouveau rôle `coach` : liaison N-N `CoachGym (coachId, gymId)`. `gymId` direct sur User reste valable pour manager/member ; pour coach, renvoyer `gyms: Gym[]` (ou `gymIds: int[]`) dans `/auth/me` et le login.
- [ ] `POST /users/create-coach` (owner only) : `{ email, firstName, lastName, phoneNumber, gymIds: int[] }` + email d'activation comme pour les managers. `PATCH /users/{id}/gyms` pour modifier les salles d'un coach (owner).

## 2. Matrice de droits (appliquée côté serveur, le client ne fait que masquer l'UI)

| Action | Owner | Manager (sa salle) | Coach (ses salles) |
|---|---|---|---|
| Créer membre, affecter abonnement | ✅ | ✅ | ❌ |
| Affecter un coach à un membre | ✅ | ✅ (coach rattaché à sa salle) | ❌ |
| Stock produits (`/store/products` CRUD) | ✅ | ✅ **sa salle uniquement** | ❌ |
| Vitrine / promo : `/showcase/*`, `/banners` (écriture), `/gyms/{id}` champs vitrine, `/gyms/{id}/photos`, `/gyms/{id}/image` | ✅ | **❌ 403** | ❌ |
| Horaires d'ouverture salle | ✅ | ❌ | ❌ |
| Créer manager / coach | ✅ | ❌ | ❌ |
| Programmes (CRUD) | ✅ | ❌ (lecture) | ❌ (lecture) |
| Affecter un programme à un membre | ✅ | **❌ 403** (lecture seule) | ✅ **ses membres affectés uniquement** |
| Planning coachs / séances (CRUD) | ✅ | ✅ sa salle | lecture de ses séances |
| Check-in membre à une séance | ✅ | ✅ | ✅ **ses séances uniquement** |
| Check-ins du jour | ✅ | ✅ sa salle | ✅ ses salles |
| Créer incident | — | ✅ (app + kiosk) | ✅ (app uniquement) |
| Répondre / clôturer incident | ✅ | ❌ | ❌ |
| Login kiosk | ✅ | ✅ | **❌** |

- [ ] Login kiosk : le refus du coach doit être côté serveur. Proposition : le kiosk envoie `client: "kiosk"` (ou header `X-Client: kiosk`) au login → 403 si `coach`/`member`. Les incidents créés avec un token kiosk portent `source: "kiosk"`.
- [ ] Toutes les listes (`/users`, `/users/gym/{gymId}/members`, `/subscriptions/*`, `/check-in/*`, `/store/*`) filtrées selon la portée du rôle ; un `gymId` hors portée → 403.

## 3. Coach ↔ Membre

- [ ] `coachId` (nullable) sur le membre (un coach principal par membre). `PATCH /members/{id}/coach { coachId | null }` (owner/manager). Le coach doit être rattaché à la salle du membre.
- [ ] `GET /coaches?gymId=` (owner/manager) — coachs d'une salle.
- [ ] `GET /coaches/me/members` (coach) — ses membres affectés.

## 4. Programmes (remplace les « plannings » actuels)

Modèle cible : **l'owner crée le programme** (modèle réutilisable : jours + exercices, comme le planning actuel mais sans `memberId`), puis **le programme est affecté à des membres**.

- [ ] `Program` : `id, title, description, level?, durationWeeks?, days[] { dayOfWeek, exercises[] }, createdBy (owner)`. CRUD owner : `/programs`, `/programs/{id}`, `/programs/{id}/days/{dayOfWeek}/exercises[/{exerciseId}]`.
- [ ] `ProgramAssignment` : `id, programId, memberId, assignedBy, startDate, endDate?, status (active|completed|cancelled)`. `POST /programs/{id}/assignments { memberIds: int[], startDate, endDate? }`, `DELETE /program-assignments/{id}`, `GET /members/{id}/programs`.
- [ ] L'app membre continue de lire « son planning du jour » : garder `/plannings/member/{memberId}` et `/plannings/next-day/{memberId}` (même forme de réponse) en les alimentant depuis l'assignation active — pas de régression côté membre.
- [ ] Migration des plannings existants : proposition = chaque planning existant devient un `Program` + une `ProgramAssignment` vers son membre. À confirmer par le serveur (volume, doublons).
- [ ] `request-help` / `respond-help` : notifier aussi le coach affecté au membre.

## 5. Planning coachs & séances

Une **séance = une plage horaire de travail d'un coach, avec un ou plusieurs membres**. Le manager affecte les plages aux coachs et doit trouver facilement des créneaux pour les membres.

- [ ] `Session` : `id, gymId, coachId, startAt, endAt, capacity (≥1), title?/type?, notes?, recurrenceId?, createdBy, status (scheduled|done|cancelled)`.
- [ ] `SessionMember` : `sessionId, memberId, status (booked|checked_in|absent|cancelled), checkedInAt?, checkedInBy?`.
- [ ] CRUD manager/owner : `POST/PATCH/DELETE /sessions`, `GET /sessions?gymId=&coachId=&from=&to=`. **Refus si chevauchement** d'une séance du même coach (409 avec la séance en conflit).
- [ ] Récurrence (souhaitable) : `POST /sessions` avec `repeat { weekly: true, until }` → crée la série ; modifier/supprimer « cette séance / toute la série ».
- [ ] Inscription : `POST /sessions/{id}/members { memberIds }`, `DELETE /sessions/{id}/members/{memberId}` (manager/owner). Refus si capacité pleine, membre sans abonnement actif, ou membre déjà dans une séance qui chevauche.
- [ ] **Recherche de créneaux** pour un membre : `GET /sessions/available?gymId=&from=&to=&coachId?=&memberId?=` → séances à venir avec places restantes (`remaining`), excluant celles qui chevauchent les séances du membre ; idéalement en privilégiant le coach affecté au membre. Respecter les horaires d'ouverture de la salle.
- [ ] Coach : `GET /coaches/me/sessions?from=&to=` (ses séances, toutes salles) avec la liste des membres.
- [ ] **Check-in séance** : `POST /sessions/{id}/check-in { memberId }` (coach de la séance, manager, owner) → `SessionMember.status = checked_in`. À trancher : crée-t-il aussi un check-in salle (décompte de quota d'abonnement) si le membre n'a pas scanné aujourd'hui ? Proposition : oui, une seule entrée salle par jour.
- [ ] Notifications FCM : membre ajouté/retiré d'une séance, rappel avant séance ; coach notifié quand une séance lui est affectée/modifiée.

## 6. Check-ins du jour (coach)

- [ ] `GET /check-in/today?gymId=` utilisable par le coach (ses salles uniquement), même forme que `/check-in/gym/{gymId}/today`. Indiquer pour chaque entrée si le membre est affecté au coach (`isMyMember`) et sa prochaine séance du jour éventuelle.

## 7. Incidents

- [ ] `Incident` : `id, gymId, createdBy, creatorRole, source (app|kiosk), title, description, category (equipment|safety|hygiene|member|other), severity (low|medium|high|critical), photoUrl?, status (open|in_progress|resolved|closed), createdAt, closedAt?, closedBy?`.
- [ ] `IncidentMessage` (fil de réponses) : `id, incidentId, authorId, body, createdAt`.
- [ ] `POST /incidents` (manager : sa salle, app ou kiosk ; coach : une de ses salles, app uniquement — refuser `source=kiosk`). Upload photo multipart comme les photos de profil.
- [ ] `GET /incidents?gymId=&status=` — owner : tout ; manager : sa salle ; coach : les siens.
- [ ] `GET /incidents/{id}` avec les messages.
- [ ] `POST /incidents/{id}/messages { body }` — owner (réponse) ; le créateur peut répondre aussi (à trancher).
- [ ] `PATCH /incidents/{id} { status }` — owner uniquement (clôture / en cours).
- [ ] FCM : nouvel incident → tous les owners ; réponse ou changement de statut → **le créateur**. Payload `data: { type: "incident", incidentId }` pour l'ouverture directe dans l'app (le client route via `NotificationRouter`).

## 8. Divers

- [ ] `/auth/me` et login : renvoyer `role`, `gymId` (manager/member), `gyms` (coach), `permissions` (owner) — le client choisit les écrans à partir de là.
- [ ] Mettre à jour `swagger.yml` (enum `role` = `[member, coach, manager, owner]`, nouveaux schémas/routes) et le transmettre au client.
- [ ] Ordre de livraison suggéré (aligné sur les tranches client) : 1) renommage manager + matrice vitrine/promo + login kiosk ; 2) coach + affectation coach↔membre ; 3) programmes + assignations + migration ; 4) séances + recherche de créneaux + check-in séance ; 5) check-ins du jour coach ; 6) incidents.

## Choix provisoires — arbitrés par l'utilisateur (2026-10-26)

1. ~~Le manager peut affecter un programme~~ → **inversé** : le manager **n'affecte pas** de programmes (403 sur `POST /programs/{id}/assignments` et `DELETE /program-assignments/{id}`). Son rôle est de planifier des séances avec un coach. Seuls l'owner et le coach (ses membres) affectent. Client : PR #31.
2. ✅ Le manager **ne peut pas** modifier les horaires d'ouverture.
3. ✅ Le check-in séance crée une entrée salle (quota) **au plus une fois par jour**.
4. ✅ Le créateur d'un incident **peut** répondre ; seul l'owner change le statut. **En plus** : un vrai chat sur le fil d'incident (voir ci-dessous).

### Ajouts issus de l'arbitrage

- **Séances typées** (server tranche 4) : champ `type` requis en `POST /sessions`, modifiable en `PATCH`, renvoyé partout, filtrable `?type=` sur `GET /sessions`, `/sessions/available`, `/coaches/me/sessions`. Enum : `discovery` (découverte), `training` (entraînement), `group_class` (cours collectif), `assessment` (bilan), `private` (coaching individuel). Défaut de migration : `training`.
- **Chat incident** (server tranche 6) : `GET /incidents/{id}/messages?after=<messageId>` (polling incrémental), `POST /incidents/{id}/read`, `unreadCount` + `lastMessage` dans `GET /incidents` et `GET /incidents/{id}`, FCM `incident` à chaque message avec `incidentId`. Pas de websocket : polling (~10 s fil ouvert) + push.

## Ajustements validés avec Claude serveur (2026-10-26)

- **Branches serveur** : pas de `staging` côté serveur ; PRs empilées sur `feat/db-server-initial` (tranche N → branche de la tranche N-1).
- **Session kiosk séparée** : login avec `client: "kiosk"` dans le body → emplacement `User.kioskSessionId` (un login kiosk ne déconnecte plus le téléphone). JWT `client: "kiosk" | "app"`. Coach/member au kiosk → 403 `{ error: "kiosk_forbidden_role" }`. La `source` d'un incident est déduite du token.
- **Renommage** : migration SQL `admin` → `manager` ; anciens JWT `type: "admin"` normalisés en `manager` par le middleware ; `admin` accepté en entrée partout, `manager` toujours renvoyé. `permissions` expose `canManageManagers` (= `canManageAdmins`) pendant la transition.
- **Coach** : `gymId` = salle principale (NOT NULL), mais la source de vérité est `gyms: [{id, displayId, name}]` — le client utilise `gyms` pour un coach. Retrait d'une salle → ses membres de cette salle passent à `coachId = null`.
- **IDs** : int partout, `displayId` inchangé.
- **Programmes** : migration 1 Planning → 1 Program + 1 ProgramAssignment (`Program.sourcePlanningId`) ; tables Planning conservées en lecture une release.
- **Séances** : modèles Prisma `TrainingSession*` mais routes `/sessions` et clé JSON `session`. Chevauchement → 409 `{ error: "session_overlap", conflicts: [...] }`. Récurrence `repeat: { weekly: true, until }` ≤ 26 semaines, tout-ou-rien ; édition/suppression `?scope=this|following|series`.
- **Fuseau** : `startAt`/`endAt` en ISO 8601 UTC ; le client envoie de l'ISO avec offset ; horaires d'ouverture interprétés en Africa/Casablanca.
- **Check-in séance** : si le membre a déjà une entrée salle aujourd'hui, pas de nouveau décompte.
- **Photo d'incident** : multipart `photo` en entrée ; en sortie `hasPhoto: bool` + `GET /incidents/{id}/photo` (binaire), pas de `photoUrl`.
- **Seed** : `coach@team-oustad.com` / `coach123` (2 salles) ; `admin@team-oustad.com` devient manager.
