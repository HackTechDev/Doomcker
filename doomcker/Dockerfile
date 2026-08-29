# Built with arch: amd64 flavor: lxde image: ubuntu:26.04
#
################################################################################
# base system
################################################################################

FROM ubuntu:26.04 as system

RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#' /etc/apt/sources.list;

# built-in packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt update \
    && apt install -y --no-install-recommends software-properties-common curl apache2-utils \
    && apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        supervisor nginx sudo net-tools zenity xz-utils \
        dbus-x11 x11-utils alsa-utils \
        mesa-utils libgl1-mesa-dri \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*
# install debs error if combine together
RUN apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        xvfb x11vnc \
        unzip firefox meld vim mc htop screen libnspr4 libnss3 wget xdg-utils fonts-liberation\
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN apt update \
    && apt install -y gpg-agent gnupg \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --no-tty --batch --yes --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
    && curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && (dpkg -i ./google-chrome-stable_current_amd64.deb || apt-get install -fy) \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

RUN apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        lxde gtk2-engines-murrine gnome-themes-extra gtk2-engines-pixbuf gtk2-engines-murrine arc-theme \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

#### GAME

# Slash'EM, Cataclysm-DDA, Crossfire, Luanti
RUN apt-get update \
    && apt-get install -y \
        slashem-sdl cataclysm-dda-sdl \
        crossfire-client crossfire-server crossfire-maps crossfire-client-images crossfire-common \
        luanti luanti-data luanti-server luanti-game-minetest \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Freedoom, Eureka (Zandronum n'est pas empaqueté pour Ubuntu 26.04, cf. UPDATE.md)
RUN apt-get update \
    && apt-get install -y freedoom eureka \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Quake (Darkplaces client + serveur) + LibreQuake (données de jeu libres, équivalent Freedoom)
RUN apt-get update \
    && apt-get install -y darkplaces darkplaces-server \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && wget -q https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/full.zip -O /tmp/librequake.zip \
    && unzip -q /tmp/librequake.zip -d /tmp \
    && mkdir -p /opt/quake \
    && mv /tmp/full/id1 /opt/quake/id1 \
    && rm -rf /tmp/librequake.zip /tmp/full \
    && mv /usr/games/darkplaces /usr/games/darkplaces-bin \
    && mv /usr/games/darkplaces-server /usr/games/darkplaces-server-bin \
    && printf '#!/bin/bash\nexec /usr/games/darkplaces-bin -basedir /opt/quake "$@"\n' > /usr/games/darkplaces \
    && printf '#!/bin/bash\nexec /usr/games/darkplaces-server-bin -basedir /opt/quake "$@"\n' > /usr/games/darkplaces-server \
    && chmod +x /usr/games/darkplaces /usr/games/darkplaces-server
COPY conf/runDarkplaces.sh /usr/games/runDarkplaces.sh
RUN chmod +x /usr/games/runDarkplaces.sh

# Slade (dépôt tiers DRD Team — pas dans les dépôts Ubuntu)
RUN wget -O- http://debian.drdteam.org/drdteam.gpg | gpg --no-tty --batch --yes --dearmor -o /usr/share/keyrings/drdteam.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/drdteam.gpg] http://debian.drdteam.org/ stable multiverse' > /etc/apt/sources.list.d/drdteam.list \
    && apt-get update \
    && apt-get install -y slade \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# TrenchBroom (éditeur de niveaux Quake, AppImage GitHub releases — pas dans les dépôts Ubuntu)
RUN wget -q https://github.com/TrenchBroom/TrenchBroom/releases/download/v2026.2/TrenchBroom-Linux-x86_64-v2026.2-Release.zip -O /tmp/trenchbroom.zip \
    && unzip -q /tmp/trenchbroom.zip -d /tmp \
    && chmod +x /tmp/TrenchBroom.AppImage \
    && cd /tmp && ./TrenchBroom.AppImage --appimage-extract >/dev/null \
    && mv /tmp/squashfs-root /opt/trenchbroom \
    && printf '#!/bin/bash\nexec /opt/trenchbroom/AppRun "$@"\n' > /usr/games/trenchbroom \
    && chmod +x /usr/games/trenchbroom \
    && rm -rf /tmp/trenchbroom.zip /tmp/TrenchBroom.AppImage /tmp/squashfs-root

# Office applications
RUN apt-get update \
    && apt-get install -y gedit gnumeric abiword gimp \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

####


# tini to fix subreap
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

# python library
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN apt-get update \
    && dpkg-query -W -f='${Package}\n' > /tmp/a.txt \
    && apt-get install -y python3-pip python3-dev build-essential \
	&& pip3 install --break-system-packages setuptools wheel && pip3 install --break-system-packages -r /tmp/requirements.txt \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && dpkg-query -W -f='${Package}\n' > /tmp/b.txt \
    && apt-get remove -y `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs` \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/* /tmp/a.txt /tmp/b.txt


################################################################################
# builder
################################################################################
FROM ubuntu:26.04 as builder


RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#' /etc/apt/sources.list;


RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg patch

# nodejs
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --no-tty --batch --yes --dearmor -o /usr/share/keyrings/yarn.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn

# build frontend
COPY web /src/web
RUN cd /src/web \
    && yarn \
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js



################################################################################
# merge
################################################################################
FROM system
LABEL maintainer="lesanglierdesardennes@gmail.com"

COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify && \
	chmod +x /usr/local/lib/web/frontend/static/websockify/run

EXPOSE 80
WORKDIR /root
ENV HOME=/home/ubuntu \
    SHELL=/bin/bash
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
