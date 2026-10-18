# Tester sur iPhone sans Mac (xtool)

[xtool](https://github.com/xtool-org/xtool) signe et installe une app iOS sur un iPhone depuis Linux / WSL, avec un Apple ID.

**Limite importante :** xtool ne sait compiler que des projets SwiftPM, pas une app Flutter, et `flutter build ios` ne fonctionne que sur macOS. Le flux est donc :

1. **GitHub Actions (macOS)** compile un `.ipa` **non signé** → workflow `ios-build.yml`
2. **WSL** : xtool **signe** ce `.ipa` avec ton Apple ID et l'**installe** sur l'iPhone via USB → `scripts/ios-install.sh`

## 1. Installation unique (WSL)

### Passer l'iPhone en USB à WSL (PowerShell admin, côté Windows)

```powershell
winget install usbipd
usbipd list                          # repérer le BUSID "Apple Mobile Device"
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>  # à refaire à chaque rebranchement
```

Si xtool renvoie `AFCClient.Error.muxError`, utiliser à la place le relais iTunes décrit dans [xtool#19](https://github.com/xtool-org/xtool/issues/19#issuecomment-2898986718).

### Outils (WSL)

```bash
sudo apt-get install usbmuxd libimobiledevice-utils
curl -fL "https://github.com/xtool-org/xtool/releases/latest/download/xtool-$(uname -m).AppImage" -o xtool
chmod +x xtool && sudo mv xtool /usr/local/bin/

xtool auth login     # connexion Apple ID
ideviceinfo          # vérifie que l'iPhone est visible (accepter "Faire confiance" sur le téléphone)
```

`xtool setup` demande aussi un `Xcode.xip`. Ce fichier n'est nécessaire que pour compiler des apps Swift avec xtool, pas pour installer notre `.ipa` : `xtool auth login` suffit.

**Mode de connexion :**
- **API Key** : nécessite un compte Apple Developer payant (99 $/an). C'est recommandé.
- **Password** : fonctionne avec un Apple ID gratuit, mais passe par des API Apple privées. Utiliser de préférence un Apple ID secondaire.

Sur l'iPhone : **Réglages → Confidentialité et sécurité → Mode développeur** doit être activé (iOS 16+).

## 2. Compiler l'IPA

GitHub → Actions → **🍎 iOS Build** → *Run workflow* → choisir l'environnement (`pprod` par défaut).

Ou avec `gh` :

```bash
gh workflow run ios-build.yml -f environment=pprod
```

## 3. Installer sur l'iPhone

```bash
scripts/ios-install.sh --download pprod        # télécharge le dernier build pprod réussi (gh requis)
scripts/ios-install.sh ~/TeamFitness-pprod.ipa # ou un .ipa déjà téléchargé
```

`XTOOL_UDID=<udid>` permet de cibler un appareil précis si plusieurs sont branchés.

## Limitations

- **Apple ID gratuit** : l'app expire au bout de **7 jours** (il faut la réinstaller), avec 3 apps maximum par appareil. Pas de capacité **Push Notifications**, donc FCM ne fonctionnera pas.
- **Build release uniquement** : un build debug Flutter ne démarre pas sur iPhone sans débogueur attaché, donc pas de hot reload. Pour itérer rapidement, utiliser l'émulateur Android ou Windows, et l'iPhone pour valider.
