#!/bin/sh

docker exec doomcker chown util01:util01 /users/util01
firefox -width 1024 -height 768 http://127.0.0.1:6080/ &
