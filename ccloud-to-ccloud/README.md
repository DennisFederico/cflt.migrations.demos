# Confluent Cloud to Confluent Cloud migration

TODO... Intro, cluster migrations between Confluent Clouds using Confluent replicator deployed as containers (or cluster linking) and Confluent Control Center in management mode to check the clusters and replicator status

## Pre-Requisites

- Access to Confluent Cloud (CloudAdmin or Cloud API-Key)
- Terraform
- Docker Compose (For replicator and C3)

## Scenarios

- Scenario Cut-over (with Replicator)
  - See [replicator/README.md](replicator/README.md)
- Scenario Fail-over (with Replicator)
  - See [replicator/README.md](replicator/README.md)
- Scenario Cluster Linking
  - See [cluster-link/README.md](cluster-link/README.md)

## Sandbox environment creation

See [terraform/README.md](terraform/README.md) for instruction on how to create the environment in Confluent Cloud.

### Other tips

- [Automatic Topic Creation in CCloud](https://docs.confluent.io/cloud/current/clusters/broker-config.html#enable-automatic-topic-creation)