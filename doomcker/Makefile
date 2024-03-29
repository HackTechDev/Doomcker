.PHONY: build run

# Default values for variables
REPO  ?= nekrofage/doomcker
TAG   ?= latest
# you can choose other base image versions
IMAGE ?= ubuntu:20.04
# choose from supported flavors (see available ones in ./flavors/*.yml)
FLAVOR ?= lxde
# armhf or amd64
ARCH ?= amd64

# These files will be generated from teh Jinja templates (.j2 sources)
templates = Dockerfile rootfs/etc/supervisor/conf.d/supervisord.conf

# Rebuild the container image
build: $(templates)
	podman build -t $(REPO):$(TAG) .

# Test run the container
# the local dir will be mounted under /src read-only
run:
	podman run --privileged --rm \
		-p 6080:80 -p 6081:443 \
		--mount type=bind,source=/home/util01,destination=/users/util01 \
		-e USER=util01 -e PASSWORD=util01 \
		-e ALSADEV=hw:2,0 \
		-e SSL_PORT=443 \
		-e RELATIVE_URL_ROOT=approot \
		-v ${PWD}/ssl:/etc/nginx/ssl \
		--device /dev/snd \
		--name doomcker \
		$(REPO):$(TAG)

# Connect inside the running container for debugging
shell:
	podman exec -it doomcker bash

# Generate the SSL/TLS config for HTTPS
gen-ssl:
	mkdir -p ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/nginx.key -out ssl/nginx.crt

clean:
	rm -f $(templates)

extra-clean:
	podman rmi $(REPO):$(TAG)
	podman image prune -f
