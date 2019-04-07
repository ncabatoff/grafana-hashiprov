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
{{ range service "prometheus|any" }}
          - name: prom-{{ .Address }}
            type: prometheus
            access: proxy
            orgId: 1
            url: http://{{ .Address }}:{{ .Port }}
            isDefault: {{ if .Tags | contains "primary" }}true{{ else }}false{{ end }}
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
              path: /alloc/data/${git_sync_dest}/${git_repo_subfolder}
      EOH
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
    task "git-sync" {
      driver = "docker"
      config {
        image = "${git_sync_docker_image}"
        args = [
          "-repo", "${git_repo}",
          "-branch", "${git_branch}",
          "-root", "/alloc/data",
          "-dest", "${git_sync_dest}",
        ]
      }
      resources {
        memory = 25
      }
    }
  }
}
