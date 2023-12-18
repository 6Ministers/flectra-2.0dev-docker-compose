#!/bin/bash

DESTINATION=$1
PORT=$2
CHAT=$3

# clone Flectra directory
git clone --depth=1 https://github.com/minhng92/flectra-2.0-docker-compose $DESTINATION
rm -rf $DESTINATION/.git

# set permission
mkdir -p $DESTINATION/postgresql
sudo chmod -R 777 $DESTINATION

# config
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf); else echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf; fi
sudo sysctl -p
sed -i 's/10020/'$PORT'/g' $DESTINATION/docker-compose.yml
sed -i 's/20020/'$CHAT'/g' $DESTINATION/docker-compose.yml

# This script setups dockerized Redash on Ubuntu 20.04.
set -eu

install_docker() {
  # Install Docker
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -qqy update
  DEBIAN_FRONTEND=noninteractive sudo -E apt-get -qqy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
  sudo apt-get -yy install apt-transport-https ca-certificates curl software-properties-common pwgen gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=""$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    ""$(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Install Docker Compose
  sudo ln -sfv /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

  # Allow current user to run Docker commands
  sudo usermod -aG docker "$USER"
}
install_docker

# run Flectra
docker-compose -f $DESTINATION/docker-compose.yml up -d

echo 'Started Flectra @ http://localhost:'$PORT' | Master Password: master.password | Live chat port: '$CHAT
