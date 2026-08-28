# MANUAL.md — Emplacement des binaires des jeux et applications

`/usr/games` est dans le `PATH` par défaut du conteneur (`/etc/environment`), donc tous les
binaires ci-dessous sont lançables directement depuis un terminal du bureau LXDE, sans
chemin complet.

| Jeu / outil | Binaire |
|---|---|
| Freedoom (moteur dsda-doom) | `/usr/games/dsda-doom` (+ `dsda-heretic`, `dsda-hexen`) |
| — WADs Freedoom | `/usr/share/games/doom/freedoom1.wad`, `freedoom2.wad` |
| Eureka (éditeur Doom) | `/usr/bin/eureka` |
| Slade (éditeur de ressources Doom) | `/usr/bin/slade` |
| Slash'EM | `/usr/games/slashem-sdl` |
| Cataclysm-DDA | `/usr/games/cataclysm-tiles` |
| Crossfire client | `/usr/games/crossfire-client-gtk2` |
| Crossfire serveur | `/usr/sbin/crossfire-server` |
| Luanti (client) | `/usr/games/luanti` (alias `/usr/games/minetest`) |
| Luanti serveur | `/usr/games/luantiserver` (alias `minetestserver`) |
| Quake (client Darkplaces) | `/usr/games/darkplaces` |
| Quake (serveur Darkplaces) | `/usr/games/darkplaces-server` |
| gedit / gnumeric / abiword | `/usr/bin/gedit`, `/usr/bin/gnumeric`, `/usr/bin/abiword` |
| GIMP | `/usr/bin/gimp` |

Note : `dsda-doom` cherchera les WADs Freedoom dans `/usr/share/games/doom/` automatiquement,
ou via `-iwad /usr/share/games/doom/freedoom2.wad`.
