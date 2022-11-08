#!/bin/sh

sudo docker rm -f $(docker ps -a -q)
sudo docker rmi -f $(docker images -q)
sudo docker volume rm $(docker volume ls -qf dangling=true)
