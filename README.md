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
      -e DOCKER_INFLUXDB_INIT_PORT=8086 \
      -e DOCKER_INFLUXDB_INIT_HOST=influxdb \
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
  -e DOCKER_INFLUXDB_INIT_PORT="$DOCKER_INFLUXDB_INIT_PORT"
  -e DOCKER_INFLUXDB_INIT_HOST="$DOCKER_INFLUXDB_INIT_HOST"
	telegraf:1.25.0
# End
```

- Grafana Dashboard Import 15650
- url: https://grafana.com/grafana/dashboards/15650-telegraf-influxdb-2-0-flux/

- Grafana Dashboard
```grafana
{
  "__inputs": [
    {
      "name": "DS_INFLUXDB",
      "label": "InfluxDB",
      "description": "",
      "type": "datasource",
      "pluginId": "influxdb",
      "pluginName": "InfluxDB"
    }
  ],
  "__elements": {},
  "__requires": [
    {
      "type": "panel",
      "id": "gauge",
      "name": "Gauge",
      "version": ""
    },
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "9.3.2"
    },
    {
      "type": "panel",
      "id": "graph",
      "name": "Graph (old)",
      "version": ""
    },
    {
      "type": "datasource",
      "id": "influxdb",
      "name": "InfluxDB",
      "version": "1.0.0"
    },
    {
      "type": "panel",
      "id": "stat",
      "name": "Stat",
      "version": ""
    },
    {
      "type": "panel",
      "id": "timeseries",
      "name": "Time series",
      "version": ""
    }
  ],
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "description": "Dashboard for displaying basic host metrics collected by telegraf and stored into the InfluxDB 2.0. Metrics are fetched by flux.",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "gnetId": 15650,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "collapsed": false,
      "datasource": {
        "type": "influxdb",
        "uid": "E-_6TMpVk"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 65058,
      "panels": [],
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "E-_6TMpVk"
          },
          "refId": "A"
        }
      ],
      "title": "Quick overview",
      "type": "row"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-red",
                "value": null
              },
              {
                "color": "dark-green",
                "value": 604800
              }
            ]
          },
          "unit": "s"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 4,
        "x": 0,
        "y": 1
      },
      "id": 65078,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop:v.timeRangeStop)\n  |> filter(fn: (r) =>\n    r.host =~ /${host}/ and\n    r._measurement == \"system\" and\n    r._field == \"uptime\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Uptime",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 70
              },
              {
                "color": "#d44a3a",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 4,
        "y": 1
      },
      "id": 65079,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true,
        "text": {}
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"disk\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"used_percent\")\n  |> filter(fn: (r) => r[\"path\"] == \"/\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Root FS Used",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 3
              },
              {
                "color": "#d44a3a",
                "value": 7
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 6,
        "y": 1
      },
      "id": 65080,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_measurement\"] == \"system\")\n  |> filter(fn: (r) => r[\"_field\"] == \"load5\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "LA (Medium)",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 8,
        "y": 1
      },
      "id": 65081,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop:v.timeRangeStop)\n  |> filter(fn: (r) =>\n    r.host == \"${host}\" and \n    r._measurement == \"system\" and\n    r._field == \"n_cpus\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "CPUs",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 70
              },
              {
                "color": "#d44a3a",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 10,
        "y": 1
      },
      "id": 65082,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true,
        "text": {}
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n    |> filter(fn: (r) => r._measurement == \"cpu\" and  r.host == \"${host}\" and r._field == \"usage_idle\" and r.cpu == \"cpu-total\")\n    |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n    |> pivot(rowKey: [\"_time\"], columnKey: [\"_field\"], valueColumn: \"_value\")\n    |> map(fn: (r) => ({r: r.usage_idle * -1.0 + 100.0}))",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "CPU usage",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 70
              },
              {
                "color": "#d44a3a",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 12,
        "y": 1
      },
      "id": 65083,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true,
        "text": {}
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"mem\")\n  |> filter(fn: (r) => r[\"_field\"] == \"used_percent\")\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "RAM usage",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 2,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 70
              },
              {
                "color": "#d44a3a",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 14,
        "y": 1
      },
      "id": 65084,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"cpu\")\n  |> filter(fn: (r) => r[\"_field\"] == \"usage_iowait\")\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"cpu\"] == \"cpu-total\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "IOWait",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 0,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 1
              },
              {
                "color": "#d44a3a",
                "value": 5
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 16,
        "y": 1
      },
      "id": 65085,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"processes\")\n  |> filter(fn: (r) => r[\"_field\"] == \"total\")\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Processes",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 0,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 1
              },
              {
                "color": "#d44a3a",
                "value": 5
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 18,
        "y": 1
      },
      "id": 65086,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"processes\")\n  |> filter(fn: (r) => r[\"_field\"] == \"total_threads\")\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Threads",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 50
              },
              {
                "color": "#d44a3a",
                "value": 70
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 20,
        "y": 1
      },
      "id": 65087,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true,
        "text": {}
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"swap\")\n  |> filter(fn: (r) => r[\"_field\"] == \"used_percent\")\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Swap Usage",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#299c46",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 20
              },
              {
                "color": "#d44a3a",
                "value": 50
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 3,
        "w": 2,
        "x": 22,
        "y": 1
      },
      "id": 65088,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {},
        "textMode": "auto"
      },
      "pluginVersion": "9.3.2",
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "groupBy": [
            {
              "params": [
                "$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"system\")\n  |> filter(fn: (r) => r[\"_field\"] == \"n_users\")\n  |> filter(fn: (r) =>  r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: last, createEmpty: false)\n  |> yield(name: \"last\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Users",
      "type": "stat"
    },
    {
      "collapsed": false,
      "datasource": {
        "type": "influxdb",
        "uid": "E-_6TMpVk"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 4
      },
      "id": 65060,
      "panels": [],
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "E-_6TMpVk"
          },
          "refId": "A"
        }
      ],
      "title": "SYSTEM - CPU, Memory, Disk",
      "type": "row"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/mem_total/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#BF1B00",
                  "mode": "fixed"
                }
              },
              {
                "id": "custom.fillOpacity",
                "value": 0
              },
              {
                "id": "custom.lineWidth",
                "value": 2
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 10,
        "w": 24,
        "x": 0,
        "y": 5
      },
      "id": 12054,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "hide": false,
          "measurement": "mem_inactive",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(total) as total, mean(used) as used, mean(cached) as cached, mean(free) as free, mean(buffered) as buffered  FROM \"mem\" WHERE host =~ /$server$/ AND $timeFilter GROUP BY time($interval), host ORDER BY asc\n\n  from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart)\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r._measurement == \"mem\")\n  |> filter(fn: (r) => r._field == \"used_percent\" or r._field == \"cached\" or r._field == \"free\" or r._field == \"buffered\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Memory usage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 10,
        "w": 24,
        "x": 0,
        "y": 15
      },
      "id": 65092,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "hide": false,
          "measurement": "cpu_percentageBusy",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(usage_user) as \"user\", mean(usage_system) as \"system\", mean(usage_softirq) as \"softirq\", mean(usage_steal) as \"steal\", mean(usage_nice) as \"nice\", mean(usage_irq) as \"irq\", mean(usage_iowait) as \"iowait\", mean(usage_guest) as \"guest\", mean(usage_guest_nice) as \"guest_nice\"  FROM \"cpu\" WHERE \"host\" =~ /$server$/ and cpu = 'cpu-total' AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart)\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r._measurement == \"cpu\")\n  |> filter(fn: (r) => r._field == \"usage_system\" or r._field == \"usage_softirq\" or r._field == \"steal\" or r._field == \"usage_nice\" or r._field == \"usage_irq\"  or r._field == \"usage_iowait\"  or r._field == \"usage_guest\"  or r._field == \"guest_nice\")\n  |> filter(fn: (r) => r.cpu =~ /$cpu$/)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")\n  ",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "CPU Usage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 25
      },
      "id": 54694,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "system_load1",
          "policy": "default",
          "query": "//SELECT mean(load1) as load1,mean(load5) as load5,mean(load15) as load15 FROM \"system\" WHERE host =~ /$server$/ AND $timeFilter GROUP BY time($interval), * ORDER BY asc\n\nfrom(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"system\")\n  |> filter(fn: (r) => r[\"_field\"] == \"load1\" or r[\"_field\"] == \"load5\" or r[\"_field\"] == \"load15\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "CPU Load",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "normal"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 25
      },
      "id": 65089,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_cpu",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "hide": false,
          "measurement": "cpu_percentageBusy",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT 100 - mean(\"usage_idle\") FROM \"cpu\" WHERE (\"cpu\" =~ /cpu[0-9].*/ AND \"host\" =~ /^$server$/) AND $timeFilter GROUP BY time($interval), \"cpu\" fill(null)\n\nfrom(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"cpu\")\n  |> filter(fn: (r) => r[\"_field\"] == \"usage_idle\")\n  |> filter(fn: (r) => r[\"cpu\"] =~ /cpu[0-9].*/)\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> pivot(rowKey: [\"_time\"], columnKey: [\"_field\"], valueColumn: \"_value\")\n  |> map(fn: (r) => ({r with usage_idle: 100.0 - r.usage_idle}))",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "CPU usage per core",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 32
      },
      "id": 28239,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "hide": false,
          "measurement": "cpu_percentageBusy",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(running) as running, mean(blocked) as blocked, mean(sleeping) as sleeping, mean(stopped) as stopped, mean(zombies) as zombies, mean(paging) as paging, mean(unknown) as unknown FROM \"processes\" WHERE host =~ /$server$/ AND $timeFilter GROUP BY time($interval), host ORDER BY asc\n\n\nfrom(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"processes\")\n  |> filter(fn: (r) => r[\"_field\"] == \"running\" or r[\"_field\"] == \"blocked\" or r[\"_field\"] == \"sleeping\" or r[\"_field\"] == \"zombies\" or r[\"_field\"] == \"paging\" or r[\"_field\"] == \"unknown\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Processes",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "ops"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 32
      },
      "id": 65097,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "hide": false,
          "measurement": "cpu_percentageBusy",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(context_switches),1s)as \"context switches\"  FROM \"kernel\" WHERE host =~ /$server$/ AND $timeFilter GROUP BY time($interval), host ORDER BY asc\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"kernel\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"context_switches\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Context Switches",
      "type": "timeseries"
    },
    {
      "collapsed": false,
      "datasource": {
        "type": "influxdb",
        "uid": "E-_6TMpVk"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 40
      },
      "id": 65096,
      "panels": [],
      "targets": [
        {
          "datasource": {
            "type": "influxdb",
            "uid": "E-_6TMpVk"
          },
          "refId": "A"
        }
      ],
      "title": "Disk",
      "type": "row"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "disk.total"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#BF1B00",
                  "mode": "fixed"
                }
              },
              {
                "id": "custom.fillOpacity",
                "value": 0
              },
              {
                "id": "custom.lineWidth",
                "value": 2
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 41
      },
      "id": 52240,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $tag_path : $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "disk_total",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(total) AS \"total\", mean(used) as \"used\", mean(free) as \"free\" FROM \"disk\" WHERE \"host\" =~ /$server$/ AND \"path\" = '/' AND $timeFilter GROUP BY time($interval), \"host\", \"path\"\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"disk\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"used\" or r[\"_field\"] == \"free\")\n  |> filter(fn: (r) => r[\"path\"] == \"/\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Root Disk usage (/)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "disk.used_percent"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#BF1B00",
                  "mode": "fixed"
                }
              },
              {
                "id": "custom.fillOpacity",
                "value": 0
              },
              {
                "id": "custom.lineWidth",
                "value": 2
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 41
      },
      "id": 65090,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_path ($tag_fstype on $tag_device)",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "disk_total",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(\"used_percent\") AS \"used_percent\" FROM \"disk\" WHERE (\"host\" =~ /^$server$/) AND $timeFilter GROUP BY time($interval), \"path\", \"device\", \"fstype\" fill(null)\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"disk\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.device =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"used_percent\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Partitions usage (%)",
      "type": "timeseries"
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "editable": true,
      "error": false,
      "fill": 1,
      "fillGradient": 0,
      "grid": {},
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 49
      },
      "hiddenSeries": false,
      "id": 33458,
      "interval": "$inter",
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "max": true,
        "min": true,
        "show": true,
        "sort": "current",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "connected",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "9.3.2",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [
        {
          "alias": "/used/",
          "color": "#BF1B00",
          "zindex": 3
        },
        {
          "alias": "/free/",
          "bars": false,
          "fill": 0,
          "lines": true,
          "linewidth": 1
        }
      ],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": true,
      "targets": [
        {
          "alias": "$tag_host: $tag_path : $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "disk_inodes_free",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(inodes_total) as \"total\", mean(inodes_free) as \"free\", mean(inodes_used) as \"used\" FROM \"disk\" WHERE \"host\" =~ /$server$/ AND \"path\" = '/' AND $timeFilter GROUP BY time($interval), \"host\", \"path\"\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"disk\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"inodes_total\" or r[\"_field\"] == \"inodes_free\" or r[\"_field\"] == \"inodes_used\")\n  |> filter(fn: (r) => r[\"path\"] == \"/\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": [],
      "timeRegions": [],
      "title": "Root (/) Disk inodes",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "cumulative"
      },
      "type": "graph",
      "xaxis": {
        "mode": "time",
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "logBase": 10,
          "min": 0,
          "show": true
        },
        {
          "format": "short",
          "logBase": 1,
          "show": true
        }
      ],
      "yaxis": {
        "align": false
      }
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "disk.used_percent"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#BF1B00",
                  "mode": "fixed"
                }
              },
              {
                "id": "custom.fillOpacity",
                "value": 0
              },
              {
                "id": "custom.lineWidth",
                "value": 2
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 49
      },
      "id": 65091,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_path ($tag_fstype on $tag_device)",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "disk_total",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT mean(\"inodes_free\") AS \"free\" FROM \"disk\" WHERE (\"host\" =~ /^$server$/) AND $timeFilter GROUP BY time($interval), \"path\", \"device\", \"fstype\" fill(null)\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"disk\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"inodes_free\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "All partitions Inodes (Free)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/total/"
            },
            "properties": [
              {
                "id": "custom.fillOpacity",
                "value": 0
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 57
      },
      "id": 61850,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "swap_in",
          "policy": "default",
          "query": "//SELECT mean(free) as \"free\", mean(used) as \"used\", mean(total) as \"total\" FROM \"swap\" WHERE host =~ /$server$/ AND $timeFilter GROUP BY time($interval), host ORDER BY asc\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"swap\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"free\" or r[\"_field\"] == \"used\" or r[\"_field\"] == \"total\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Swap usage (bytes)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 57
      },
      "id": 26024,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "swap_in",
          "policy": "default",
          "query": "//SELECT mean(\"in\") as \"in\", mean(\"out\") as \"out\" FROM \"swap\" WHERE host =~ /$server$/ AND $timeFilter GROUP BY time($interval), host ORDER BY asc\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"swap\")\n  |> filter(fn: (r) => r.host == \"${host}\")\n  |> filter(fn: (r) => r[\"_field\"] == \"in\" or r[\"_field\"] == \"out\" or r[\"_field\"] == \"swap\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Swap I/O bytes",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "iops"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 65
      },
      "id": 13782,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $tag_name: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "io_reads",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(reads),1s) as \"read\" FROM \"diskio\" WHERE \"host\" =~ /$server$/ AND \"name\" =~ /$disk$/ AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"diskio\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.name =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"reads\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "$tag_host: $tag_name: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "io_reads",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(writes),1s) as \"write\" FROM \"diskio\" WHERE \"host\" =~ /$server$/ AND \"name\" =~ /$disk$/  AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"diskio\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.name =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"write\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "C",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Disk I/O requests",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "ms"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 65
      },
      "id": 56720,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $tag_name: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "io_reads",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(read_time),1s) as \"read\" FROM \"diskio\" WHERE \"host\" =~ /$server$/ AND \"name\" =~ /$disk$/  AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"diskio\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.name =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"read_time\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "$tag_host: $tag_name: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "io_reads",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(write_time),1s) as \"write\" FROM \"diskio\" WHERE \"host\" =~ /$server$/ AND \"name\" =~ /$disk$/ AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"diskio\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.name =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"write_time\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Disk I/O time",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "${DS_INFLUXDB}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "stepAfter",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 73
      },
      "id": 60200,
      "interval": "$inter",
      "links": [],
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "8.1.0",
      "targets": [
        {
          "alias": "$tag_host: $tag_name: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "io_reads",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(read_bytes),1s) as \"read\" FROM \"diskio\" WHERE \"host\" =~ /$server$/ AND \"name\" =~ /$disk$/ AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"diskio\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.name =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"read_bytes\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        },
        {
          "alias": "$tag_host: $tag_name: $col",
          "datasource": {
            "type": "influxdb",
            "uid": "${DS_INFLUXDB}"
          },
          "dsType": "influxdb",
          "function": "mean",
          "groupBy": [
            {
              "interval": "auto",
              "params": [
                "auto"
              ],
              "type": "time"
            },
            {
              "key": "host",
              "params": [
                "tag"
              ],
              "type": "tag"
            },
            {
              "key": "path",
              "params": [
                "tag"
              ],
              "type": "tag"
            }
          ],
          "measurement": "io_reads",
          "orderByTime": "ASC",
          "policy": "default",
          "query": "//SELECT non_negative_derivative(mean(write_bytes),1s) as \"write\" FROM \"diskio\" WHERE \"host\" =~ /$server$/ AND \"name\" =~ /$disk$/ AND $timeFilter GROUP BY time($interval), *\n\nfrom(bucket:  \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"diskio\")\n  |> filter(fn: (r) => r.host == \"${host}\" and r.name =~ /$disk$/)\n  |> filter(fn: (r) => r[\"_field\"] == \"write_bytes\")\n  |> derivative(unit: 1s, nonNegative: true)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
          "rawQuery": true,
          "refId": "C",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "title": "Disk I/O bytes",
      "type": "timeseries"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 37,
  "style": "dark",
  "tags": [
    "telegraf",
    "influxdb",
    "flux"
  ],
  "templating": {
    "list": [
      {
        "allFormat": "glob",
        "current": {
          "selected": false,
          "text": "InfluxDB",
          "value": "InfluxDB"
        },
        "datasource": "InfluxDB-telegraf",
        "hide": 0,
        "includeAll": false,
        "label": "",
        "multi": false,
        "name": "datasource",
        "options": [],
        "query": "influxdb",
        "queryValue": "",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "type": "datasource"
      },
      {
        "current": {},
        "datasource": {
          "type": "influxdb",
          "uid": "${DS_INFLUXDB}"
        },
        "definition": "buckets()",
        "hide": 0,
        "includeAll": false,
        "multi": false,
        "name": "bucket",
        "options": [],
        "query": "buckets()",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "type": "query"
      },
      {
        "current": {},
        "datasource": {
          "type": "influxdb",
          "uid": "${DS_INFLUXDB}"
        },
        "definition": "import \"influxdata/influxdb/schema\"\n\nschema.tagValues(bucket: \"${bucket}\", tag: \"host\")",
        "hide": 0,
        "includeAll": false,
        "label": "host",
        "multi": false,
        "name": "host",
        "options": [],
        "query": "import \"influxdata/influxdb/schema\"\n\nschema.tagValues(bucket: \"${bucket}\", tag: \"host\")",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "auto": true,
        "auto_count": 100,
        "auto_min": "30s",
        "current": {
          "selected": false,
          "text": "auto",
          "value": "$__auto_interval_inter"
        },
        "hide": 0,
        "includeAll": false,
        "label": "Interval",
        "multi": false,
        "name": "inter",
        "options": [
          {
            "selected": true,
            "text": "auto",
            "value": "$__auto_interval_inter"
          },
          {
            "selected": false,
            "text": "1s",
            "value": "1s"
          },
          {
            "selected": false,
            "text": "5s",
            "value": "5s"
          },
          {
            "selected": false,
            "text": "10s",
            "value": "10s"
          },
          {
            "selected": false,
            "text": "15s",
            "value": "15s"
          },
          {
            "selected": false,
            "text": "30s",
            "value": "30s"
          },
          {
            "selected": false,
            "text": "1m",
            "value": "1m"
          },
          {
            "selected": false,
            "text": "10m",
            "value": "10m"
          },
          {
            "selected": false,
            "text": "30m",
            "value": "30m"
          },
          {
            "selected": false,
            "text": "1h",
            "value": "1h"
          },
          {
            "selected": false,
            "text": "6h",
            "value": "6h"
          },
          {
            "selected": false,
            "text": "12h",
            "value": "12h"
          },
          {
            "selected": false,
            "text": "1d",
            "value": "1d"
          },
          {
            "selected": false,
            "text": "7d",
            "value": "7d"
          },
          {
            "selected": false,
            "text": "14d",
            "value": "14d"
          },
          {
            "selected": false,
            "text": "30d",
            "value": "30d"
          },
          {
            "selected": false,
            "text": "60d",
            "value": "60d"
          },
          {
            "selected": false,
            "text": "90d",
            "value": "90d"
          }
        ],
        "query": "1s,5s,10s,15s,30s,1m,10m,30m,1h,6h,12h,1d,7d,14d,30d,60d,90d",
        "queryValue": "",
        "refresh": 2,
        "skipUrlSync": false,
        "type": "interval"
      },
      {
        "allValue": ".*",
        "current": {},
        "datasource": {
          "uid": "$datasource"
        },
        "definition": "import \"influxdata/influxdb/schema\"\nschema.tagValues(bucket: \"${bucket}\", tag: \"cpu\")",
        "hide": 0,
        "includeAll": true,
        "label": "CPU",
        "multi": false,
        "name": "cpu",
        "options": [],
        "query": "import \"influxdata/influxdb/schema\"\nschema.tagValues(bucket: \"${bucket}\", tag: \"cpu\")",
        "refresh": 1,
        "regex": "^cpu.*",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": ".*",
        "current": {},
        "datasource": {
          "uid": "$datasource"
        },
        "definition": "import \"influxdata/influxdb/schema\"\nschema.tagValues(bucket: \"${bucket}\", tag: \"device\")",
        "hide": 0,
        "includeAll": true,
        "label": "disk",
        "multi": false,
        "name": "disk",
        "options": [],
        "query": "import \"influxdata/influxdb/schema\"\nschema.tagValues(bucket: \"${bucket}\", tag: \"device\")",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query"
      },
      {
        "allValue": ".*",
        "current": {},
        "datasource": {
          "uid": "$datasource"
        },
        "definition": "import \"influxdata/influxdb/schema\"\nschema.tagValues(bucket: \"${bucket}\", tag: \"interface\")",
        "hide": 0,
        "includeAll": true,
        "label": "interface",
        "multi": true,
        "name": "interface",
        "options": [],
        "query": "import \"influxdata/influxdb/schema\"\nschema.tagValues(bucket: \"${bucket}\", tag: \"interface\")",
        "refresh": 1,
        "regex": "^(?!.*veth|all|tap).*",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tagsQuery": "",
        "type": "query"
      }
    ]
  },
  "time": {
    "from": "now-5m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "browser",
  "title": "Telegraf Metrics dashboard for InfluxDB 2.0 (Flux)",
  "uid": "7JdIfTn9z",
  "version": 3,
  "weekStart": ""
}
```