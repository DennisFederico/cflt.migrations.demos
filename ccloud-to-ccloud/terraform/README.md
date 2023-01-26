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

An API-Key and Secret of an user or SA (Service Account) with enough privileges to create environments and clusters (OrganizationAdmin)

## Steps

1. Make a copy of `terraform.tfvars.template` as `terraform.tfvars`
2. Edit `terraform.tfvars`:
   - Set the API-Key and Secret with (OrganizationAdmin)
   - Name the environments and clusters to create
   - Specify the topics to create in the Source cluster
   - ...

3. Initialize terraform `terraform init`
4. Apply the configuration to provision the resources `terraform apply`
5. When done, to show the output `terraform output resources-data`
