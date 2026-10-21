# Installer l'app iOS avec Sideloadly (sans Mac)

Guide pour le personnel de la salle : installer le fichier `.ipa` de Team Oustad sur un iPhone, depuis un PC Windows ou un Mac, avec [Sideloadly](https://sideloadly.io/). Pas besoin de compte développeur payant ni de connaissances techniques.

## Ce qu'il faut

- Un **PC Windows ou Mac** (pas besoin de WSL/Linux pour cette méthode).
- **iTunes** installé sur le PC (même sans l'utiliser, ses pilotes Apple sont nécessaires pour que Windows reconnaisse l'iPhone) — [téléchargement direct Apple](https://www.apple.com/itunes/) (pas la version Microsoft Store).
- **Sideloadly** : [sideloadly.io](https://sideloadly.io/) → bouton *Download*.
- Un **câble USB** (Lightning ou USB‑C selon le modèle).
- Un **identifiant Apple** (email + mot de passe) — un compte Apple gratuit suffit, pas besoin du programme développeur à 99 $/an.
- Le fichier **`TeamOustad.ipa`** (lien "Télécharger le fichier IPA" dans l'écran d'accueil du kiosque, ou directement `https://kiosk.team-oustad.com/TeamOustad.ipa`).

## Étapes

### 1. Installer les outils (une seule fois)

1. Installe iTunes depuis le site d'Apple et ouvre-le une première fois (pour que les pilotes s'installent).
2. Installe Sideloadly et lance-le.

### 2. Connecter l'iPhone

1. Branche l'iPhone au PC avec le câble USB.
2. Sur l'iPhone, une fenêtre **"Faire confiance à cet ordinateur ?"** apparaît → appuie sur **Faire confiance** et entre le code de l'iPhone.
3. Dans Sideloadly, l'iPhone doit apparaître dans la liste déroulante en haut (sinon, débranche/rebranche le câble).

### 3. Installer l'app

1. Télécharge `TeamOustad.ipa` (lien sur l'écran du kiosque).
2. Glisse-dépose le fichier `.ipa` dans la grande zone au centre de Sideloadly (ou clique sur l'icône en forme de note de musique pour le sélectionner).
3. Dans le champ **Apple ID**, saisis l'adresse email du compte Apple à utiliser pour signer l'app.
4. Clique sur **Start**.
5. Une fenêtre de connexion Apple s'ouvre : entre le mot de passe du compte (et le code à 6 chiffres si la double authentification est activée).
6. Laisse Sideloadly travailler (il télécharge un certificat, signe l'app, puis l'installe) — ça prend 1 à 2 minutes.

### 4. Faire confiance à l'app sur l'iPhone

L'icône "Team Oustad" apparaît sur l'écran d'accueil, mais iOS bloque son lancement tant qu'on n'a pas validé le certificat :

1. Sur l'iPhone : **Réglages → Général → VPN et gestion de l'appareil**.
2. Sous "App développeur", touche l'adresse email Apple utilisée dans Sideloadly.
3. Touche **Faire confiance à "..."**, puis confirme.
4. Lance l'app.

## Limitations (Apple ID gratuit)

- **Expire après 7 jours** : l'app se désinstalle automatiquement et il faut refaire l'étape 3 avec Sideloadly (le `.ipa` et les identifiants restent les mêmes, ça prend 1 minute).
- **3 apps maximum** installées en même temps par ce moyen sur le même iPhone.
- **Pas de notifications push** (FCM) avec ce mode de signature — fonctionnalité réservée à la version Play Store / App Store.

## Problèmes fréquents

| Symptôme | Solution |
|---|---|
| Sideloadly ne voit pas l'iPhone | Réinstaller/réparer iTunes, rebrancher le câble, redémarrer Sideloadly |
| "Impossible de vérifier l'app" au lancement | Refaire l'étape 4 (faire confiance au profil) |
| L'app a disparu après quelques jours | Normal avec un Apple ID gratuit (7 jours) → réinstaller via Sideloadly |
| Erreur de mot de passe Apple alors qu'il est correct | La double authentification bloque Sideloadly → utiliser un mot de passe d'application généré sur [appleid.apple.com](https://appleid.apple.com/) |

Pour l'équipe technique qui génère/signe l'IPA elle-même via WSL + xtool, voir [`IOS_XTOOL.md`](IOS_XTOOL.md).
