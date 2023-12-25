#!/bin/sh

sudo podman rm -f $(podman ps -a -q)
sudo podman rmi -f $(podman images -q)
sudo podman volume rm $(podman volume ls -qf dangling=true)
