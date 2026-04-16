#!/bin/bash

set -e

# Wipe all Docker containers and images
echo "Wiping all Docker containers and images..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi $(docker images -q) --force 2>/dev/null || true

# Setup network and tor-proxy image
docker network create tor-net
docker pull quay.io/mylastres0rt05_redhat/nova_dromidia-proxy:latest
docker tag quay.io/mylastres0rt05_redhat/nova_dromidia-proxy:latest tor-proxy

# Start tor-proxy containers
echo "Starting tor-proxy containers..."
# SOCKS ports: 9050,9052,9054,9056,9058  API ports: 5000-5004
for i in $(seq 0 4); do
  SOCKS=$((9050 + i * 2))
  CTRL=$((9051 + i * 2))
  API=$((5000 + i))
  docker run -d --name tor-$SOCKS --network tor-net \
    -e SOCKS_PORT=$SOCKS -e CONTROL_PORT=$CTRL -e API_PORT=$API \
    -p $SOCKS:$SOCKS -p $API:$API tor-proxy
done

# Pull and tag thor-session image
echo "Pulling images from quay.io..."
docker pull quay.io/mylastres0rt05_redhat/nova_dromidia:latest
docker tag quay.io/mylastres0rt05_redhat/nova_dromidia:latest thor-session:v1.44

# Create shared log file
mkdir -p ~/thor-logs && touch ~/thor-logs/sessions.log

# Wait for Tor bootstrap
echo "Waiting for Tor to bootstrap..."
until docker logs tor-9050 2>&1 | grep -q "Bootstrapped 100%"; do sleep 2; done

# Start thor-session containers
echo "Starting thor-session containers..."
for i in $(seq 0 4); do
  SOCKS=$((9050 + i * 2))
  API=$((5000 + i))
  SESSION=$((i + 1))
  HOST_PORT=$((8080 + i))
  docker run -d --name thor-session-$SESSION --network tor-net \
    -e SOCKS_PORT=$SOCKS -e API_PORT=$API -e TOR_HOST=tor-$SOCKS \
    -p $HOST_PORT:8080 thor-session:v1.44
done

docker logs -f thor-session-1
