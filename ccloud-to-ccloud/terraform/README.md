# Confluent Cloud Resource provision

We will create the Confluent Cloud resources needed for the Demo using Terraform.

- Environments
- Standard Clusters (to use RBAC)
- Topics
- Service Accounts for replicator (both clusters)
- Service Accounts for producer application (source cluster)
- Service Accounts for consumer application (both clusters)
- Needed Role-bindings
- API-Keys and secrets

## Requirements

A Cloud API-Key and Secret of an user or SA (Service Account) with enough privileges to create environments and clusters (OrganizationAdmin)

## Steps

1. Make a copy of `terraform.tfvars.template` as `terraform.tfvars`
2. Edit `terraform.tfvars`:
   - Set the Cloud API-Key and Secret (or API Key of user with OrganizationAdmin role)
   - Name the environments and clusters to create as source and target cluster
   - Specify the topics to create in the Source cluster
   - Specify a regular expression for the replicator that capture one or more of the topcis above

3. Initialize terraform `terraform init`
4. Apply the configuration to provision the resources `terraform apply`
5. When done, to show the output `terraform output resources-data`

### General configuration/connection files

1. Write the launch script for replicator `terraform output -raw submit-replicator_sh > ../replicator/submit-replicator.sh`
2. Write the standard connection properties for the source cluster `terraform output -raw source_cluster_kafka_properties > ../replicator/source-kafka.properties`
3. Write the standard connection properties for the target cluster `terraform output -raw target_cluster_kafka_properties > ../replicator/target-kafka.properties`

### Prepare Docker Compose Environment

1. Write Docker Compose environment data `terraform output -raw compose_env > ../replicator/docker/.env`

### Prepare CFK Variables

1. Write the credentials secret file for the source cluster `terraform output -raw cfk_secrets_source_cluster> ../replicator/cfk/cfk-source-cluster-creds.txt`
2. Write the credentials secret file for the source cluster `terraform output -raw cfk_secrets_target_cluster > ../replicator/cfk/cfk-target-cluster-creds.txt`
3. Write the credentials secret file for schema registry `terraform output -raw cfk_secrets_schema_registry > ../replicator/cfk/cfk-sr-cluster-creds.txt`
4. Write the Kustomize patch file for Connect Cluster `terraform output -raw k8s_kustomize_connect > ../replicator/cfk/platform-template/kustomize-connect.yaml`
5. Write the Kustomize patch file for Control Center `terraform output -raw k8s_kustomize_controlcenter > ../replicator/cfk/platform-template/kustomize-controlcenter.yaml`
6. Write the Kustomize patch file for the Connector `terraform output -raw k8s_kustomize_connector > ../replicator/cfk/connector-template/kustomize-replicator.yaml`

## Replication Scenarios

See [/replicator/README.md](../replicator/README.md)
