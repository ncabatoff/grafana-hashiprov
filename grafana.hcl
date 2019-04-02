# WARNING: This is a Terraform-templated file.  All single dollar signs
# refer to Terraform template variables.  Double dollar signs are escaped
# dollar signs which refer to Nomad variables.
job "grafana" {
  datacenters = ["${consul_datacenter}"]
  type = "service"
  group "grafana" {
    task "grafana" {
      template {
        destination = "local/provisioning/datasources/prometheus.yml"
        data = <<EOH
          apiVersion: 1

          datasources:
{{ range $index, $element := service "prometheus|any" }}
          - name: prom-{{ $element.Address }}
            type: prometheus
            access: proxy
            orgId: 1
            url: http://{{ $element.Address }}:{{ $element.Port }}
            isDefault: {{ eq $index 0 }}
            version: 1
            editable: false
{{ end }}
      EOH
      }
      template {
        destination = "local/provisioning/dashboards/dashboards.yml"
        data = <<EOH
          apiVersion: 1

          providers:
          - name: 'default'
            orgId: 1
            folder: 'static'
            type: file
            disableDeletion: false
            updateIntervalSeconds: 60
            editable: true
            options:
              path: /local/dashboards
      EOH
      }
      artifact {
        source = "http://consul.service.${consul_datacenter}.consul:8500/v1/kv/${consul_dashboard_key}?raw=true"
        destination = "local/dashboards/"
        options {
          checksum = "md5:${dashboard_checksum}"
        }
      }
      driver = "docker"
      config {
        image = "${grafana_docker_image}"
        network_mode = "${grafana_network_mode}"
        port_map {
          http = "3000"
        }
        dns_servers = [
          "$${attr.driver.docker.bridge_ip}"
        ]
      }
      env {
        GF_LOG_LEVEL = "DEBUG"
        GF_PATHS_PROVISIONING = "/local/provisioning"
      }
      resources {
        memory = 100
        network {
          port "http" {
            static = "3000"
          }
        }
      }
      service {
        name = "grafana"
        port = "http"
        check {
          type = "http"
          path = "/api/health"
          interval = "30s"
          timeout = "2s"
        }
      }
    }
  }
}
