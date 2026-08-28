# UPDATE.md — Historique des interventions

Journal des changements effectués sur le projet Doomcker, session par session.

---

## 2026-08-27

### 21:58 — Nettoyage de l'environnement Podman/Docker (pas de commit, opérations d'infra)

- Vérification post-redémarrage : aucun conteneur Podman actif (le projet tourne sous Podman, pas Docker).
- Côté Docker (installation séparée, autres projets sur la machine) : suppression des conteneurs orphelins/anciens (`ddev-*`, `dazzling_einstein`, `eloquent_hypatia`), des images associées (~7,9 Go) et du build cache (~3,6 Go). Les volumes Docker (bases de données d'autres projets : `labodev_*`, `geekcollection_*`, etc.) ont été **conservés** intentionnellement.
- Test fonctionnel de Podman : pull + run réussis (`hello-world`).

### 21:13 — `[Migrate] Ubuntu 26.04 base image` (commit `46c9c0f`)

Migration de l'image de base `ubuntu:20.04` → `ubuntu:26.04`, avec modernisation des chaînes d'outils backend et frontend qui ne compilaient plus dessus.

- **Dockerfile** : `FROM ubuntu:26.04` (stages `system` et `builder`) ; migration des clés APT Chrome/Yarn de `apt-key` (supprimé sur Ubuntu récent) vers `gpg --dearmor` + `signed-by` ; ajout de `--break-system-packages` pour `pip3 install` (PEP 668 / Python 3.14).
- **Suppression volontaire** de la section `#### GAME` (Freedoom/Zandronum, Slade, Eureka, Crossfire, Minetest, Cataclysm-DDA, Slash'EM, Quake/darkplaces/TrenchBroom) et des dossiers `doomcker/conf/zandronum/` et `doomcker/conf/quake/`, pour isoler la migration de base avant réintégration des jeux un par un.
- **Backend Python** (`rootfs/usr/local/lib/web/backend/requirements.txt`) : `gevent==1.4.0` / `greenlet==0.4.15` (2019) ne compilaient plus contre l'API C de Python 3.14. Versions remontées via résolution pip réelle : Flask 3.1.3, Werkzeug 3.1.8, gevent 26.8.0, greenlet 3.5.5, Jinja2 3.1.6, etc.
- **Node.js** (stage `builder`) : `setup_12.x` (EOL, rejeté par le codename "resolute" d'Ubuntu 26.04) → `setup_20.x` (dépôt NodeSource "nodistro").
- **Frontend** (`doomcker/web`) : migration complète **webpack 3.6 → 5.110** et **Babel 6 → 7** (Node ≥17 + webpack 3 = crash OpenSSL sur MD4). Remplacement de `extract-text-webpack-plugin` → `mini-css-extract-plugin`, `optimize-css-assets-webpack-plugin` → `css-minimizer-webpack-plugin`, `uglifyjs-webpack-plugin` → `terser-webpack-plugin`, `CommonsChunkPlugin` → `optimization.splitChunks`, `url-loader`/`file-loader` → Asset Modules natifs webpack5, `vue-loader` 13 → 15 (+ `VueLoaderPlugin`). Retrait de `eslint-loader` (mort, incompatible webpack5) — `npm run lint` reste disponible en standalone.
- **Validation** : build réel des 3 stages Dockerfile + smoke test conteneur (nginx, backend, Xvfb/x11vnc/noVNC/LXDE tous `RUNNING`, `/api/health` → 200).

### 21:36 — `[Fix] websockify multiprocessing + launch script home path` (commit `a06ce5a`)

- **Bug** : `websockify` fork un process par connexion via `multiprocessing.Process()`, en s'appuyant sur l'héritage du socket d'écoute déjà ouvert. Python 3.14 a changé la méthode de démarrage par défaut de `multiprocessing` sous Linux (`fork` → `forkserver`), qui ré-exécute le script d'entrée dans l'enfant au lieu de le cloner — celui-ci retente alors de bind le port 6081 déjà occupé, crashe, et la connexion WebSocket est reset (502 côté nginx). Le bureau noVNC restait donc inaccessible.
- **Fix** : forçage explicite de `multiprocessing.set_start_method('fork')` dans `doomcker/web/static/websockify/websockify/websockifyserver.py`.
- **Bonus** : `launchBrowser.sh` et `launchBrowserSSL.sh` faisaient `chown util01:util01 /users/util01` (chemin inexistant) au lieu de `/home/util01` (le vrai volume monté) — échouait silencieusement à chaque lancement. Corrigé dans les deux scripts.

### 21:51 — `[Fix] websockify array.fromstring/tostring removed in Python 3.9+` (commit `cdf13aa`)

- **Bug** : malgré le fix précédent, le handshake WebSocket réussissait (`101 Switching Protocols`) mais la connexion échouait juste après avec `'array.array' object has no attribute 'fromstring'` côté serveur → noVNC affichait "Failed to connect to server". `array.array.fromstring()`/`.tostring()` ont été supprimés en Python 3.9 (remplacés par `.frombytes()`/`.tobytes()`), et le fallback de (dé)masquage des frames WebSocket (`websocket.py`, chemin sans `numpy`) utilisait encore l'ancienne API.
- **Fix** : `fromstring()` → `frombytes()`, `tostring()` → `tobytes()` dans `doomcker/web/static/websockify/websockify/websocket.py` (y compris la branche `numpy`, inactive ici mais concernée par le même renommage depuis numpy 2.0).
- **Validation end-to-end** : un vrai client WebSocket (`websockets`, Python) reçoit la bannière `RFB 003.008\n` d'x11vnc à travers toute la chaîne nginx → websockify → x11vnc.

### Rebuilds et redémarrages du conteneur

Après chaque correctif websockify, l'image `nekrofage/doomcker:latest` a été reconstruite (`./buildDoomckerContainer.sh`) et le conteneur `doomcker` recréé (`./stopDoomckerContainer.sh` puis `make run`) pour intégrer le fix nativement dans l'image, avec vérification systématique post-redémarrage (statut supervisord + handshake VNC réel).

**Résultat final confirmé par l'utilisateur : fonctionnel.**

---

## 2026-08-28

### 18:32 — `[Add] Slash'EM, Cataclysm-DDA, Crossfire, Luanti (Minetest)` (commit `3bb95ac`)

Reprise de la réinstallation des jeux dans la section `#### GAME` du Dockerfile, vidée pendant la migration Ubuntu 26.04.

- **Vérification préalable** de la disponibilité des paquets sur les dépôts Ubuntu 26.04 (`resolute`) via un conteneur `ubuntu:26.04` jetable (`apt-get install --simulate`), avant tout édition du Dockerfile — conformément au principe "valider avant de commit".
- **Ajoutés** : `slashem-sdl`, `cataclysm-dda-sdl`, `crossfire-client`, `crossfire-server`, `crossfire-maps`, `crossfire-client-images`, `crossfire-common`, `luanti`, `luanti-data`, `luanti-server`, `luanti-game-minetest` — tous présents en `universe`.
- **Minetest a été renommé "Luanti"** (projet upstream, 2024/2025) : les paquets Ubuntu 26.04 suivent ce renommage (`minetest` existe toujours en alias mais `luanti*` est le nom canonique désormais) ; `luanti-game-minetest` fournit le jeu de base historique (sub-game) pour le moteur Luanti.
- **Non disponibles en apt** (aucun résultat sur main/universe/multiverse, `E: Unable to locate package`) : `slade`, `gzdoom`, `trenchbroom` — nécessiteront une autre méthode d'installation (PPA tiers, AppImage, ou build depuis les sources). Reporté à une prochaine session.
- **Validation** : build réel du stage `system` (paquets s'installent sans erreur), puis build complet des 3 stages via `./buildDoomckerContainer.sh`, arrêt/relance du conteneur (`./stopDoomckerContainer.sh` + `./runDoomckerWeb.sh`), vérification post-redémarrage : tous les services supervisord `RUNNING`, `/api/health` → 200, les 11 paquets confirmés installés (`dpkg -l`) dans le conteneur relancé.

### 18:48 — `[Add] Freedoom et Eureka` (commit `8892cca`)

- **Ajoutés** : `freedoom` (WADs Doom libres) et `eureka` (éditeur de niveaux Doom), tous deux disponibles en `universe` sur Ubuntu 26.04.
- **Bonus involontaire** : `freedoom` recommande `dsda-doom | doom-engine` (Recommends, installés par défaut car aucun `--no-install-recommends` sur ce bloc) → `dsda-doom` (source port Doom axé speedrun/démos) est donc installé automatiquement comme moteur.
- **Zandronum non ajouté** : confirmé absent de tous les dépôts Ubuntu 26.04 (`E: Unable to locate package`, main/universe/multiverse), comme `slade`/`gzdoom`/`trenchbroom`. Reporté à une session dédiée aux paquets hors-apt (PPA, AppImage, ou build depuis les sources).
- **Validation** : build réel du stage `system`, build complet 3 stages, arrêt/relance du conteneur, vérification post-redémarrage : services supervisord `RUNNING`, `/api/health` → 200, `freedoom`/`eureka`/`dsda-doom` confirmés installés (`dpkg -l`).

### 19:13 — `[Add] Darkplaces (client + serveur) pour Quake` (commit `6f3a77d`)

- **Ajoutés** : `darkplaces` (client) et `darkplaces-server`, tous deux disponibles en `universe` sur Ubuntu 26.04 — binaires `/usr/games/darkplaces` et `/usr/games/darkplaces-server`.
- **Validation** : build réel du stage `system`, build complet 3 stages, arrêt/relance du conteneur, vérification post-redémarrage : services supervisord `RUNNING`, `/api/health` → 200, `darkplaces`/`darkplaces-server` confirmés installés (`dpkg -l` + binaires présents).
