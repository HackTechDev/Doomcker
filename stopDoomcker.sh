#!/bin/sh

podman stop $(podman ps -a -q --filter ancestor=nekrofage/doomcker:latest --format="{{.ID}}")
