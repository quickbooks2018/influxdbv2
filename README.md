# Influxdb v2

- Docker Custom Network for Service discovery
```network
docker network create monitoring --attachable
```
- influxdb
```influxdb
docker run --name influxdb -id --network monitoring --restart unless-stopped -p 8086:8086 \
      -v $PWD/influxdb/data:/var/lib/influxdb2 \
      -v $PWD/influxdb/config:/etc/influxdb2 \
      -e DOCKER_INFLUXDB_INIT_MODE=setup \
      -e DOCKER_INFLUXDB_INIT_USERNAME=cloudgeeks \
      -e DOCKER_INFLUXDB_INIT_PASSWORD=12345678 \
      -e DOCKER_INFLUXDB_INIT_ORG=cloudgeeks \
      -e DOCKER_INFLUXDB_INIT_BUCKET=telegraf \
      -e DOCKER_INFLUXDB_INIT_RETENTION=1w \
      -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=my-super-secret-auth-token \
      influxdb:2.6.0
```

- Grafana
```grafana
docker run --name grafana -p 8080:3000 --network monitoring --restart unless-stopped -id grafana/grafana:9.3.2
```

- Telegraf Agent in docker container
```telegraf
#!/bin/bash
# https://hub.docker.com/_/telegraf

HOSTNAME="Docker-Cloudgeeks-CA"
HOSTIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN='my-super-secret-auth-token'
DOCKER_INFLUXDB_INIT_ORG='cloudgeeks'
DOCKER_INFLUXDB_INIT_BUCKET='telegraf'
SERVER="${HOSTNAME}"-"${HOSTIP}"
INFLUXDB_ENDPOINT='influxdb'

export HOSTNAME
export HOSTIP
export SERVER
export INFLUX_TOKEN
export DOCKER_INFLUXDB_INIT_ADMIN_TOKEN
export DOCKER_INFLUXDB_INIT_ORG
export DOCKER_INFLUXDB_INIT_BUCKET
export INFLUXDB_ENDPOINT

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
 urls = ["http://${INFLUXDB_ENDPOINT}:8086"]

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


chmod 666 /var/run/docker.sock


docker run -id --name=telegraf --network=monitoring --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
	-v $PWD/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-v /:/hostfs:ro \
	-e HOST_ETC=/hostfs/etc \
	-e HOST_PROC=/hostfs/proc \
	-e HOST_SYS=/hostfs/sys \
	-e HOST_VAR=/hostfs/var \
	-e HOST_RUN=/hostfs/run \
	-e HOST_MOUNT_PREFIX=/hostfs \
    -e DOCKER_INFLUXDB_INIT_ORG="$DOCKER_INFLUXDB_INIT_ORG" \
    -e DOCKER_INFLUXDB_INIT_BUCKET="$DOCKER_INFLUXDB_INIT_BUCKET" \
    -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN="$DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" \
	telegraf:1.25.0
# End
```

- Grafana Dashboard Import 15650
- url: https://grafana.com/grafana/dashboards/15650-telegraf-influxdb-2-0-flux/