#!/bin/sh

docker stop $(docker ps -a -q --filter ancestor=nekrofage/doomcker:latest --format="{{.ID}}")
