#!/bin/bash
# Purpose: Influxdb v2 Grafana Stack
# Maintainer: info@cloudgeeks.ca

DOCKER_INFLUXDB_INIT_MODE='setup'
DOCKER_INFLUXDB_INIT_USERNAME='cloudgeeks'
DOCKER_INFLUXDB_INIT_PASSWORD='12345678'
DOCKER_INFLUXDB_INIT_ORG='cloudgeeks'
DOCKER_INFLUXDB_INIT_BUCKET='telegraf'
DOCKER_INFLUXDB_INIT_RETENTION='1w'
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN='my-super-secret-auth-token'
DOCKER_INFLUXDB_INIT_PORT='8086'
DOCKER_INFLUXDB_INIT_HOST='influxdb'

# Docker socket permissions till reboot to make persistent after reboot use docker-socket-permissions.sh
chmod 666 /var/run/docker.sock

cat << EOF > docker-compose.yaml
---
services:
  influxdb:
    container_name: influxdb
    image: influxdb:2.6.0
    volumes:
      - influxdb-storage:/var/lib/influxdb2:rw
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=${DOCKER_INFLUXDB_INIT_MODE}
      - DOCKER_INFLUXDB_INIT_USERNAME=${DOCKER_INFLUXDB_INIT_USERNAME}
      - DOCKER_INFLUXDB_INIT_PASSWORD=${DOCKER_INFLUXDB_INIT_PASSWORD}
      - DOCKER_INFLUXDB_INIT_ORG=${DOCKER_INFLUXDB_INIT_ORG}
      - DOCKER_INFLUXDB_INIT_BUCKET=${DOCKER_INFLUXDB_INIT_BUCKET}
      - DOCKER_INFLUXDB_INIT_RETENTION=${DOCKER_INFLUXDB_INIT_RETENTION}
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}
      - DOCKER_INFLUXDB_INIT_PORT=${DOCKER_INFLUXDB_INIT_PORT}
      - DOCKER_INFLUXDB_INIT_HOST=${DOCKER_INFLUXDB_INIT_HOST}
    restart: unless-stopped
    ports:
      - 8086:8086

  telegraf:
    container_name: telegraf
    image: telegraf:1.25.0
    volumes:
      - ${PWD}/telegraf.conf:/etc/telegraf/telegraf.conf:rw
    environment:
      - DOCKER_INFLUXDB_INIT_ORG=${DOCKER_INFLUXDB_INIT_ORG}
      - DOCKER_INFLUXDB_INIT_BUCKET=${DOCKER_INFLUXDB_INIT_BUCKET}
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN}
      - DOCKER_INFLUXDB_INIT_PORT=${DOCKER_INFLUXDB_INIT_PORT}
      - DOCKER_INFLUXDB_INIT_HOST=${DOCKER_INFLUXDB_INIT_HOST}

    depends_on:
      - influxdb

  grafana:
    container_name: grafana
    image: grafana/grafana:latest
    volumes:
      - grafana-storage:/var/lib/grafana:rw
    depends_on:
      - influxdb
    ports:
      - 3000:3000

volumes:
  grafana-storage:
  influxdb-storage:
EOF

docker compose -p influxdb up -d

# End