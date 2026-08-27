#!/bin/sh

podman exec doomcker chown util01:util01 /home/util01
firefox -width 1024 -height 768 https://127.0.0.1:6081/ &
