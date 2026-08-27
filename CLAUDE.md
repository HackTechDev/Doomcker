# CLAUDE.md

Ce fichier fournit des indications à Claude Code (claude.ai/code) lorsqu'il travaille sur le code de ce dépôt.

## Vue d'ensemble du projet

Doomcker est un fork de `docker-ubuntu-vnc-desktop` qui empaquette un bureau Ubuntu 20.04 (LXDE), accessible depuis un navigateur via noVNC, préchargé avec des jeux rétro et leurs éditeurs : Zandronum/Freedoom, Quake (darkplaces) + TrenchBroom, Slade/Eureka (éditeurs Doom), Crossfire, Minetest, Cataclysm-DDA, Slash'EM, ainsi que quelques applications bureautiques (GIMP, Gnumeric, AbiWord, gedit). Il est construit et exécuté avec **Podman**, et non Docker, même si les composants internes de l'image (Dockerfile, supervisord, nginx, noVNC) sont inchangés par rapport au projet d'origine.

Deux sous-modules git sont nécessaires pour le frontend : `doomcker/web/static/novnc` et `doomcker/web/static/websockify`. Exécutez `git submodule update --init --recursive` après le clonage s'ils sont vides.

## Commandes courantes

Tous les workflows podman passent par `doomcker/Makefile`, avec de simples scripts wrapper à la racine du dépôt (`buildDoomckerContainer.sh`, `runDoomckerWeb.sh`, `stopDoomckerContainer.sh`, `createVolume.sh`, `launchBrowser.sh` / `launchBrowserSSL.sh`, `listAllPodmanImageVolume.sh`, `removeAllPodmanImageVolume.sh`) qui se contentent de faire `cd doomcker` puis d'appeler la cible `make` correspondante.

```sh
# Construire l'image (depuis doomcker/)
FLAVOR=lxqt ARCH=amd64 IMAGE=ubuntu:18.04 make build   # FLAVOR vaut lxde par défaut, IMAGE vaut ubuntu:20.04
# ou depuis la racine du dépôt :
./buildDoomckerContainer.sh

# Lancer l'image construite (monte ./ssl, un volume podman nommé "util01", expose 6080/80 et 6081/443)
make run
./runDoomckerWeb.sh

# Générer des certificats SSL auto-signés dans doomcker/ssl/
make gen-ssl

# Ouvrir un shell dans le conteneur en cours d'exécution pour le débogage
make shell

# Arrêter le conteneur en cours d'exécution
./stopDoomckerContainer.sh

# Créer le volume nommé que le conteneur monte sur /home/util01
./createVolume.sh
```

Accédez à l'application en cours d'exécution via `http://127.0.0.1:6080/` (ou `https://127.0.0.1:6081/` pour le SSL) — `launchBrowser.sh` / `launchBrowserSSL.sh` font cela et corrigent d'abord les droits sur `/users/util01` dans le conteneur.

**Piège :** `make clean` supprime `Dockerfile` et `rootfs/etc/supervisor/conf.d/supervisord.conf`, en les traitant comme le résultat d'une génération à partir de templates Jinja (`generate.py` en amont). Ce script générateur n'existe pas dans ce dépôt — ces deux fichiers sont commités directement et modifiés à la main. Ne lancez pas `make clean` / `make extra-clean` sauf à être prêt à restaurer ces fichiers depuis git ; il n'y a autrement aucun moyen de les régénérer.

### Frontend (application Vue 2 dans `doomcker/web`)

```sh
cd doomcker/web
yarn                                    # installer les dépendances
BACKEND=http://127.0.0.1:6080 npm run dev   # serveur de dev pointant vers un backend en cours d'exécution
npm run build                           # build de production -> web/dist (ce que le Dockerfile COPY dans l'image)
npm run lint
npm run e2e                             # e2e Nightwatch uniquement — `npm run test` est cassé : il appelle
                                         # `npm run unit`, mais aucun script "unit" / config karma n'existe
```

### Backend (application Flask/gevent intégrée à l'image dans `rootfs/usr/local/lib/web/backend`)

Modifiez en local puis reconstruisez, ou itérez en direct dans un conteneur en cours d'exécution (le code source est monté en lecture seule sous `/src` par `make run`) :

```sh
make shell
supervisorctl -c /etc/supervisor/supervisord.conf stop web
cd /src/image/usr/local/lib/web/backend
./run.py --debug
```

Il n'existe pas de suite de tests pour le backend ni pour la configuration des jeux/rootfs.

## Architecture

Le Dockerfile est un build en trois étapes :

1. **`system`** — base Ubuntu 20.04. Installe supervisord, nginx, Xvfb, x11vnc, LXDE, et tous les paquets de jeux/éditeurs (Zandronum, Quake/darkplaces/TrenchBroom, Slade, Eureka, Crossfire, Minetest, Cataclysm-DDA, etc. — voir la section `#### GAME`). Installe aussi `tini` (PID 1 / subreaper) et les dépendances pip du backend Python depuis `rootfs/usr/local/lib/web/backend/requirements.txt`.
2. **`builder`** — étape Ubuntu séparée avec Node 12 + Yarn, utilisée uniquement pour faire `yarn build` du frontend dans `web/` vers `web/dist`.
3. **image finale** — part de `FROM system`, copie le frontend construit depuis `builder` vers `/usr/local/lib/web/frontend/`, puis superpose l'intégralité de l'arborescence `rootfs/` sur `/` (c'est de là que viennent la config nginx, la config supervisord et `startup.sh`). Le point d'entrée est `/startup.sh`, exécuté sous `tini`.

Câblage des composants à l'exécution (voir `doomcker/ARCHITECTURE.md` pour plus de détails), tous démarrés/surveillés par **supervisord** (`rootfs/etc/supervisor/conf.d/supervisord.conf`) :

- **Xvfb** fait tourner un serveur X en mémoire sur `DISPLAY :1`.
- **x11vnc** exporte cet affichage via VNC (port 5900).
- **noVNC + websockify** (sous-modules git dans `web/static/`) font le pont entre VNC et un client WebSocket/canvas HTML5, servi sur le port 6081.
- **Backend Flask** (`rootfs/usr/local/lib/web/backend`, paquet nommé `novnc2`) écoute sur le port 6079, et expose `/api/state`, `/api/health`, `/api/reset`, `/resize`, et `/api/live.flv` (un flux écran+son basé sur ffmpeg via X11-grab et ALSA). `state.py` suit/réconcilie la résolution d'écran souhaitée par rapport à la résolution réelle et pilote `apply_and_restart`.
- **nginx** (`rootfs/etc/nginx/`) est le point d'entrée unique sur les ports 80/443, faisant du reverse-proxy vers le backend et noVNC, et servant le frontend Vue construit.
- **Frontend Vue** (`web/src`, construit avec webpack via `web/build/*.conf.js`) encapsule le canvas noVNC et appelle l'API backend (par ex. pour redimensionner l'affichage à la taille de la fenêtre du navigateur au chargement).
- **`startup.sh`** s'exécute en premier au démarrage du conteneur : gère les variables d'environnement `VNC_PASSWORD`/`HTTP_PASSWORD`/`X11VNC_ARGS`/`OPENBOX_ARGS`/`RESOLUTION`/`SSL_PORT`/`RELATIVE_URL_ROOT`/`USER`/`PASSWORD` en réécrivant sur place les configs supervisord et nginx, puis exécute `tini -- supervisord`.

Les installateurs et ressources des jeux/éditeurs se trouvent sous `doomcker/conf/<jeu>/` (par ex. `conf/zandronum/install_zandronum.sh`, `conf/quake/id1.tar.gz` + `lancerDarkplaces*.sh`) et sont copiés (`COPY`) puis exécutés directement depuis la section `#### GAME` du Dockerfile — c'est l'endroit où ajouter ou modifier un jeu empaqueté.

`doomcker/flavors/*.yml` (lxde/lxqt/xfce4) décrivent le système déprécié de "flavor" de bureau basé sur des templates Jinja, référencé par le README d'origine ; comme le Dockerfile de ce dépôt est commité directement plutôt que généré à partir d'un template, changer de flavor implique aujourd'hui de modifier à la main les lignes `apt install` spécifiques à LXDE dans le Dockerfile.
