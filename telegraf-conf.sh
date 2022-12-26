#!/bin/bash
# https://hub.docker.com/_/telegraf

HOSTNAME="Docker-Cloudgeeks-CA"
HOSTIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN='my-super-secret-auth-token'
DOCKER_INFLUXDB_INIT_ORG='cloudgeeks'
DOCKER_INFLUXDB_INIT_BUCKET='telegraf'
SERVER="${HOSTNAME}"-"${HOSTIP}"
DOCKER_INFLUXDB_INIT_HOST='influxdb'
DOCKER_INFLUXDB_INIT_PORT='8086'

export HOSTNAME
export HOSTIP
export SERVER
export INFLUX_TOKEN
export DOCKER_INFLUXDB_INIT_ADMIN_TOKEN
export DOCKER_INFLUXDB_INIT_ORG
export DOCKER_INFLUXDB_INIT_BUCKET
export DOCKER_INFLUXDB_INIT_HOST
export DOCKER_INFLUXDB_INIT_PORT

# Telegraf Setup
cat << EOF > telegraf.conf
 [global_tags]
[agent]
  interval = "60s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = "$SERVER"
  omit_hostname = false
[[outputs.influxdb_v2]]
 ## The URLs of the InfluxDB cluster nodes.
 ##
 ## Multiple URLs can be specified for a single cluster, only ONE of the
 ## urls will be written to each interval.
 ## urls exp: http://127.0.0.1:8086
 urls = ["http://${DOCKER_INFLUXDB_INIT_HOST}:${DOCKER_INFLUXDB_INIT_PORT}"]

 ## Token for authentication.
 token = "$DOCKER_INFLUXDB_INIT_ADMIN_TOKEN"

 ## Organization is the name of the organization you wish to write to; must exist.
 organization = "$DOCKER_INFLUXDB_INIT_ORG"

 ## Destination bucket to write into.
 bucket = "$DOCKER_INFLUXDB_INIT_BUCKET"
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
[[inputs.docker]]  
 endpoint = "unix:///var/run/docker.sock"
container_name_include = []
container_name_exclude = []
[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
EOF
# End