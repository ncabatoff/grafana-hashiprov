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

variable "git_sync_docker_image" {
  default = "k8s.gcr.io/git-sync:v3.1.1"
}
variable "git_repo" {
  default = "https://github.com/ncabatoff/grafana-dashboards"
}
variable "git_repo_subfolder" {
  default = "dashboards"
}
variable "git_branch" {
  default = "master"
}
variable "git_sync_dest" {
  default = "dashboards"
}

resource "nomad_job" "grafana" {
  jobspec = "${data.template_file.grafana_hcl.rendered}"
}

data "template_file" "grafana_hcl" {
  template = "${file("grafana.hcl")}"
  vars = {
    consul_datacenter = "${var.consul_datacenter}"
    grafana_docker_image = "${var.grafana_docker_image}"
    grafana_network_mode = "${var.grafana_network_mode}"
    git_sync_docker_image = "${var.git_sync_docker_image}"
    git_repo = "${var.git_repo}"
    git_repo_subfolder = "${var.git_repo_subfolder}"
    git_branch = "${var.git_branch}"
    git_sync_dest = "${var.git_sync_dest}"
  }
}
