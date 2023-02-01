# Quick instructions for Deployment with CFK

Includes Connect cluster for replicator and C3 for management
TODO... ingress for C3, workaround: `kubectl port-forward`

**Pre-requesites**:

- Kubernetes cluster (local env: k3d / docker for desktop)
- kubectl (configured for the above)
- Helm (to install CFK)

## Setup Operator (CFK)

Create namespace:
`kubectl create namespace confluent`

Install Operator:

```bash
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent
```

## Credentials

- Create files with Terraform: (see. [Prepare CFK variables](../../terraform/README.md#prepare-cfk-variables))

```bash
# From terraform folder
terraform output -raw cfk_secrets_source_cluster> ../replicator/cfk/cfk-source-cluster-creds.txt
terraform output -raw cfk_secrets_target_cluster > ../replicator/cfk/cfk-target-cluster-creds.txt
terraform output -raw cfk_secrets_schema_registry > ../replicator/cfk/cfk-sr-cluster-creds.txt
```

- Create secrets in k8s

```bash
kubectl -n confluent create secret generic ccloud-source-credentials --from-file=plain.txt=cfk-source-cluster-creds.txt
kubectl -n confluent create secret generic ccloud-target-credentials --from-file=plain.txt=cfk-target-cluster-creds.txt
kubectl -n confluent create secret generic ccloud-sr-credentials --from-file=basic.txt=cfk-sr-cluster-creds.txt
```

## Platform CRD

Prepare deployment CRD yaml file from the provided [template](cp-platform.yaml.template) using `Kustomize`

- Prepare the kustomize path files with Terraform: (see. [Prepare CFK variables](../../terraform/README.md#prepare-cfk-variables))

```bash
# From terraform folder
terraform output -raw k8s_kustomize_connect > ../replicator/cfk/platform-template/kustomize-connect.yaml
terraform output -raw k8s_kustomize_controlcenter > ../replicator/cfk/platform-template/kustomize-controlcenter.yaml
terraform output -raw k8s_kustomize_connector > ../replicator/cfk/connector-template/kustomize-replicator.yaml
```

- Kustomize and deploy the platform CRD

```bash
# From /replicator/cfk folder
kubectl kustomize platform-template/ > cp-platform.yaml
kubectl apply -f cp-platform.yaml
```

- Open Control Center Dashboard

TODO... Ingress for C3

```bash
# KUBECTL port-forward works good in a local deployment, but it blocks the commandline. An Ingress is a better alternative
kubectl port-forward controlcenter-0 9021:9021 -n confluent
open http://localhost:9021
```

- Kustomize and Deploy the Replicator/Connector CRD

```bash
# From /replicator/cfk folder
kubectl kustomize connector-template/ > replicator.yaml
kubectl apply -f replicator.yaml
```

- (Optional) Deploy Replicator Connector as JSON from Control Center

Use control center to deploy the replicator connector from the Json file built using terraform

```bash
# From terraform folder
terraform output -raw replicator_connector_json > ../replicator/cfk/connector-replicator.json
```
