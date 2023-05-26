#!/bin/sh

sudo apt-get remove docker docker-engine

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y docker-ce

sudo groupadd docker
sudo usermod -aG docker $USER
sudo usermod -aG docker gouser
newgrp docker

sudo systemctl enable docker
