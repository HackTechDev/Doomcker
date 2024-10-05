#!/bin/sh

podman stop $(podman ps -a -q --filter ancestor=localhost/nekrofage/doomcker:latest --format="{{.ID}}")
