# Loki datasource
resource "grafana_data_source" "loki" {
  type = "loki"
  name = "Loki"
  url  = "http://loki.loki.svc.cluster.local:3100"

  is_default = true

  json_data_encoded = jsonencode({
    maxLines = 1000
  })
}

# Folder for network/syslog dashboards
resource "grafana_folder" "network" {
  title = "Network"
}

# Syslog dashboard
resource "grafana_dashboard" "syslog" {
  folder = grafana_folder.network.id

  config_json = jsonencode({
    title = "Syslog"
    uid   = "syslog"
    time = {
      from = "now-1h"
      to   = "now"
    }
    refresh = "30s"
    panels = [
      {
        id    = 1
        type  = "logs"
        title = "All Syslog"
        gridPos = {
          h = 12
          w = 24
          x = 0
          y = 0
        }
        targets = [
          {
            datasource = { type = "loki", uid = grafana_data_source.loki.uid }
            expr       = "{job=\"syslog\"}"
            refId      = "A"
          }
        ]
        options = {
          showTime        = true
          showLabels      = true
          showCommonLabels = false
          wrapLogMessage  = true
          prettifyLogMessage = false
          enableLogDetails = true
          sortOrder       = "Descending"
        }
      },
      {
        id    = 2
        type  = "timeseries"
        title = "Log Volume"
        gridPos = {
          h = 6
          w = 24
          x = 0
          y = 12
        }
        targets = [
          {
            datasource = { type = "loki", uid = grafana_data_source.loki.uid }
            expr       = "sum(count_over_time({job=\"syslog\"}[1m]))"
            refId      = "A"
            legendFormat = "logs/min"
          }
        ]
        fieldConfig = {
          defaults = {
            custom = {
              drawStyle = "bars"
              fillOpacity = 50
            }
          }
        }
      },
      {
        id    = 3
        type  = "logs"
        title = "Errors & Warnings"
        gridPos = {
          h = 10
          w = 24
          x = 0
          y = 18
        }
        targets = [
          {
            datasource = { type = "loki", uid = grafana_data_source.loki.uid }
            expr       = "{job=\"syslog\"} |~ \"(?i)(error|warn|fail|crit)\""
            refId      = "A"
          }
        ]
        options = {
          showTime   = true
          showLabels = true
          sortOrder  = "Descending"
        }
      }
    ]
    templating = {
      list = []
    }
    schemaVersion = 39
  })
}

# UniFi-specific dashboard
resource "grafana_dashboard" "unifi" {
  folder = grafana_folder.network.id

  config_json = jsonencode({
    title = "UniFi"
    uid   = "unifi"
    time = {
      from = "now-1h"
      to   = "now"
    }
    refresh = "30s"
    panels = [
      {
        id    = 1
        type  = "logs"
        title = "UniFi Logs"
        gridPos = {
          h = 14
          w = 24
          x = 0
          y = 0
        }
        targets = [
          {
            datasource = { type = "loki", uid = grafana_data_source.loki.uid }
            expr       = "{job=\"syslog\"}"
            refId      = "A"
          }
        ]
        options = {
          showTime        = true
          showLabels      = true
          enableLogDetails = true
          sortOrder       = "Descending"
        }
      },
      {
        id    = 2
        type  = "stat"
        title = "Logs (1h)"
        gridPos = {
          h = 4
          w = 6
          x = 0
          y = 14
        }
        targets = [
          {
            datasource = { type = "loki", uid = grafana_data_source.loki.uid }
            expr       = "sum(count_over_time({job=\"syslog\"}[1h]))"
            refId      = "A"
          }
        ]
      },
      {
        id    = 3
        type  = "stat"
        title = "Errors (1h)"
        gridPos = {
          h = 4
          w = 6
          x = 6
          y = 14
        }
        targets = [
          {
            datasource = { type = "loki", uid = grafana_data_source.loki.uid }
            expr       = "sum(count_over_time({job=\"syslog\"} |~ \"(?i)error\"[1h]))"
            refId      = "A"
          }
        ]
        fieldConfig = {
          defaults = {
            color = { mode = "fixed", fixedColor = "red" }
          }
        }
      }
    ]
    schemaVersion = 39
  })
}
