#!/bin/bash

set -e
  #curl "https://raw.githubusercontent.com/0smid0s/ads-sandbox-v6/refs/heads/main/init_.sh" | sudo sh
#REPO_URL="https://github.com/0smid0s/ads-sandbox-v7.git"
#DIR_NAME="ads-sandbox*"
#DIR_NAME_2="ads-sandbox-v7"

# Wipe all Docker containers and images
echo "Wiping all Docker containers and images..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi  $(docker images -q) --force   2>/dev/null || true

# oooo **************
docker network create tor-net
docker pull quay.io/mylastres0rt05_redhat/nova_dromidia-proxy:latest
docker tag quay.io/mylastres0rt05_redhat/nova_dromidia-proxy:latest tor-proxy
echo "Starting tor-proxy containers..."
docker run -d --name tor-9050 --network tor-net -e SOCKS_PORT=9050 -e CONTROL_PORT=9051 -e API_PORT=5000 -p 9050:9050 -p 5000:5000 tor-proxy


# Pull images from quay.io
echo "Pulling images from quay.io..."

docker pull quay.io/mylastres0rt05_redhat/nova_dromidia:latest


# Tag for local use

docker tag quay.io/mylastres0rt05_redhat/nova_dromidia:latest thor-session:v1.44


# Create shared log file
mkdir -p ~/thor-logs && touch ~/thor-logs/sessions.log

# Deploy 6 tor-proxy containers
echo "Waiting for Tor to bootstrap..."
until docker logs tor-9050 2>&1 | grep -q "Bootstrapped 100%"; do sleep 2; done

echo "Starting thor-session containers..."
docker run -d --name thor-session --network tor-net -e SOCKS_PORT=9050 -e API_PORT=5000 -e TOR_HOST=tor-9050 -p 8080:8080 thor-session:v1.44
docker logs -f thor-session


echo "All containers running. Tailing logs..."
#tail -f ~/thor-logs/sessions.log
