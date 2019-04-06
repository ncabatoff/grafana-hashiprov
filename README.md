# grafana-hashiprov: Provision static Grafana using HashiCorp tools.

This repo solves the problem of how to deploy Grafana and configure it with
datasources and dashboards, where:

* the datasources are Prometheus servers registered in Consul
* you want Grafana to run as a Nomad job
* you have Consul DNS available in your environment
* you want to store your dashboards in a Git repo

Neither the datasources nor dashboards will be modifiable via the Grafana UI.
This is a feature.

## Usage

Put your dashboards into a repo, e.g. https://github.com/ncabatoff/grafana-dashboards.

```bash
terraform init
terraform apply
```

When you want to update the dashboards, repeat the above.  The existing Grafana
job will be stopped and a new one created with the updated provisioning.

## Caveats

### 1. Nomad Provider

This relies on the Terraform 
[Nomad Provider](https://www.terraform.io/docs/providers/nomad/index.html).
This may not suit your production needs due to 
[Issue #1](https://github.com/terraform-providers/terraform-provider-nomad/issues/1):
if changes are made to the Nomad job outside of Terraform, Terraform won't know.

Workaround if you ever get into a bad state:

* stop the Nomad job, then
* ```terraform destroy -target=nomad_job.grafana```
* ```terraform apply```

