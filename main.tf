terraform {
  backend "consul" {
    path = "terraform"
  }
}
# * If you run a local nomad agent and don't use TLS: do nothing.
# * If you run a local nomad agent with TLS: set env var
#   NOMAD_ADDR=https://localhost:4646
# * If you don't run a local nomad agent but have DNS hooked up to Consul, set
#   env var
#   NOMAD_ADDR=https://nomad.service.dc1.consul:4646
#   possibly adjusting https/http and dc1.
provider "nomad" {}
# * If you run a local consul agent and don't use TLS: do nothing.
# * If you run a local consul agent with TLS: set env var
#   CONSUL_HTTP_ADDR=https://localhost:8500
# * If you don't run a local nomad agent but have DNS hooked up to Consul, set
#   env var
#   CONSUL_HTTP_ADDR=https://consul.service.dc1.consul:4646
#   possibly adjusting https/http and dc1.
provider "consul" {}

variable "dashboards_tgz" {
  default = "./dashboards.tgz"
}
variable "consul_datacenter" {
  default = "dc1"
}
variable "grafana_docker_image" {
  default = "grafana/grafana:5.1.0"
}
variable "grafana_network_mode" {
  # Why use host network mode?  We could avoid it if we used a direct
  # datasource, instead of proxy, but then the user's browser would need
  # to be able to do Consul DNS resolution.
  default = "host"
}
variable "consul_dashboard_key" {
  default = "grafana/dashboards.tgz"
}

data "local_file" "dashboards" {
  filename = "${var.dashboards_tgz}"
}

resource "consul_keys" "grafana_dashboards" {
  key {
    path = "${var.consul_dashboard_key}"
    value = "${data.local_file.dashboards.content}"
  }
}

resource "nomad_job" "grafana" {
  jobspec = "${data.template_file.grafana_hcl.rendered}"
}

data "template_file" "grafana_hcl" {
  template = "${file("grafana.hcl")}"
  vars = {
    dashboard_checksum = "${md5(data.local_file.dashboards.content)}"
    consul_datacenter = "${var.consul_datacenter}"
    consul_dashboard_key = "${var.consul_dashboard_key}"
    grafana_docker_image = "${var.grafana_docker_image}"
    grafana_network_mode = "${var.grafana_network_mode}"
  }
}
