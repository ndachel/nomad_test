#!/usr/bin/env bash
set -e

echo "Installing Docker..."
sudo curl -sSL https://get.docker.com/ | sh
sudo sh -c "echo \"DOCKER_OPTS='--dns 172.17.42.1 --dns 8.8.8.8 --dns-search service.consul'\" >> /etc/default/docker"
sudo service docker restart
sudo usermod -aG docker ubuntu
