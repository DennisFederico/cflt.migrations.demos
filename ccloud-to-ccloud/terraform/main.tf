# Confluent Provider Configuration
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.25.0"
    }
  }
}

# Option #1 when managing multiple clusters in the same Terraform workspace
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret = var.confluent_cloud_api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

resource "confluent_environment" "source_environment" {
  display_name = var.source_environment_name
}

resource "confluent_environment" "target_environment" {
  display_name = var.target_environment_name
}

resource "confluent_kafka_cluster" "source_kafka-cluster" {
  display_name = var.source_kafka_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "europe-west1"
  standard {}

  environment {
    id = confluent_environment.source_environment.id
  }
}

resource "confluent_kafka_cluster" "target_kafka-cluster" {
  display_name = var.target_kafka_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "europe-west2"
  standard {}

  environment {
    id = confluent_environment.target_environment.id
  }
}

#######
# CLUSTER OWNERS Service Accounts with ResourceOwner role at Cluster Level
resource "confluent_service_account" "source_cluster-sa" {
  display_name = "${confluent_kafka_cluster.source_kafka-cluster.display_name}-cluster-sa"
  description  = "${confluent_kafka_cluster.source_kafka-cluster.display_name} Cluster Owner Service account"
}

resource "confluent_service_account" "target_cluster-sa" {
  display_name = "${confluent_kafka_cluster.target_kafka-cluster.display_name}-cluster-sa"
  description  = "${confluent_kafka_cluster.target_kafka-cluster.display_name} Cluster Owner Service account"
}

# ROLE-BINDING
# See. https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html#ccloud-rbac-roles
# DeveloperRead / DeveloperWrite / DeveloperManage / ResourceOwner
resource "confluent_role_binding" "source_cluster-sa-owner-resource-owner" {
  principal   = "User:${confluent_service_account.source_cluster-sa.id}"
  role_name   = "CloudClusterAdmin"  
  crn_pattern = confluent_kafka_cluster.source_kafka-cluster.rbac_crn
}

resource "confluent_role_binding" "target_cluster-sa-owner-resource-owner" {
  principal   = "User:${confluent_service_account.target_cluster-sa.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.target_kafka-cluster.rbac_crn
}

# API-KEYS TO "AUTHENTICATE" THE SERVICE ACCOUNTS
resource "confluent_api_key" "source_cluster-sa-kafka-api-key" {
  display_name = "source_cluster-sa-kafka-api-key"
  description  = "Kafka API Key that is owned by '${confluent_service_account.source_cluster-sa.display_name}' service account"
  owner {
    id          = confluent_service_account.source_cluster-sa.id
    api_version = confluent_service_account.source_cluster-sa.api_version
    kind        = confluent_service_account.source_cluster-sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.source_kafka-cluster.id
    api_version = confluent_kafka_cluster.source_kafka-cluster.api_version
    kind        = confluent_kafka_cluster.source_kafka-cluster.kind

    environment {
      id = confluent_environment.source_environment.id
    }
  }
  depends_on = [ confluent_service_account.source_cluster-sa ]
}

resource "confluent_api_key" "target_cluster-sa-kafka-api-key" {
  display_name = "target_cluster-sa-kafka-api-key"
  description  = "Kafka API Key that is owned by '${confluent_service_account.target_cluster-sa.display_name}' service account"
  owner {
    id          = confluent_service_account.target_cluster-sa.id
    api_version = confluent_service_account.target_cluster-sa.api_version
    kind        = confluent_service_account.target_cluster-sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.target_kafka-cluster.id
    api_version = confluent_kafka_cluster.target_kafka-cluster.api_version
    kind        = confluent_kafka_cluster.target_kafka-cluster.kind

    environment {
      id = confluent_environment.target_environment.id
    }
  }
  depends_on = [ confluent_service_account.target_cluster-sa ]
}

### CREATION OF TOPICS IN THE SOURCE CLUSTER
resource "confluent_kafka_topic" "source_topics" {
  count = length(var.source_topics)
  
  kafka_cluster {
    id = confluent_kafka_cluster.source_kafka-cluster.id
  }
  rest_endpoint = confluent_kafka_cluster.source_kafka-cluster.rest_endpoint

  topic_name         = var.source_topics[count.index]
  partitions_count   = var.topics_partition
  # config = {
  #   "retention.hours"      = "1"
  # }
  
  credentials {    
    key    = confluent_api_key.source_cluster-sa-kafka-api-key.id
    secret = confluent_api_key.source_cluster-sa-kafka-api-key.secret
  }

  depends_on = [ confluent_kafka_cluster.source_kafka-cluster ]
}

### USER FOR REPLICATION WITH DEVELOPER READ ACCESS TO THE SOURCE TOPICS
# CREACION DEL USUARIO DE SERVICIO DE LA APLICACION CON PERMISO LECTURA/ESCRITURA
### NOTE: WE WILL USE THE OWNER SERVICE ACCOUNT OF THE TARGET CLUSTER FOR WRITING
resource "confluent_service_account" "source_replicator-sa" {
  display_name = "replicator-sa"
  description  = "Service account for the Replicator"
}

# ASSIGN ROLES TO THE APPLICATION SA (DeveloperRead and DeveloperManage)
# https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/index.html#crep-with-rbac
# https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/index.html#acls-to-read-from-the-source-cluster
resource "confluent_role_binding" "source_replicator-sa-manage" {
  count = length(var.source_topics)
  principal   = "User:${confluent_service_account.source_replicator-sa.id}"
  role_name   = "DeveloperManage"
  crn_pattern = "${confluent_kafka_cluster.source_kafka-cluster.rbac_crn}/kafka=${confluent_kafka_cluster.source_kafka-cluster.id}/topic=${var.source_topics[count.index]}*"
}
resource "confluent_role_binding" "source_replicator-sa-read" {
  count = length(var.source_topics)
  principal   = "User:${confluent_service_account.source_replicator-sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.source_kafka-cluster.rbac_crn}/kafka=${confluent_kafka_cluster.source_kafka-cluster.id}/topic=${var.source_topics[count.index]}*"
}
# resource "confluent_role_binding" "source_replicator-sa-write_timestamps" {
#   principal   = "User:${confluent_service_account.source_replicator-sa.id}"
#   role_name   = "DeveloperWrite"
#   crn_pattern = "${confluent_kafka_cluster.source_kafka-cluster.rbac_crn}/kafka=${confluent_kafka_cluster.source_kafka-cluster.id}/topic=__consumer_timestamps"
# }
resource "confluent_role_binding" "source_replicator-sa-consumer_group" {  
  principal = "User:${confluent_service_account.source_replicator-sa.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.source_kafka-cluster.rbac_crn}/kafka=${confluent_kafka_cluster.source_kafka-cluster.id}/group=${var.replicator_consumer_group_prefix}*"
}

resource "confluent_api_key" "source_replicator-sa-kafka-api-key" {
  display_name = "source_replicator-sa-kafka-api-key"
  description  = "Kafka API Key that is owned by '${confluent_service_account.source_replicator-sa.display_name}' service account"
  owner {
    id          = confluent_service_account.source_replicator-sa.id
    api_version = confluent_service_account.source_replicator-sa.api_version
    kind        = confluent_service_account.source_replicator-sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.source_kafka-cluster.id
    api_version = confluent_kafka_cluster.source_kafka-cluster.api_version
    kind        = confluent_kafka_cluster.source_kafka-cluster.kind

    environment {
      id = confluent_environment.source_environment.id
    }
  }
  depends_on = [ confluent_service_account.source_replicator-sa ]  
}

### CREATION OF TOPICS FOR CONNECT/REPLICATOR IN THE TARGET CLUSTER
resource "confluent_kafka_topic" "connect_replicator_internal_configs-topic" { 
  kafka_cluster {
    id = confluent_kafka_cluster.target_kafka-cluster.id
  }
  rest_endpoint = confluent_kafka_cluster.target_kafka-cluster.rest_endpoint

  topic_name         = "connect-replicator-configs"
  partitions_count   = 1
  config = {
    "cleanup.policy"      = "compact"
  }
  
  credentials {    
    key    = confluent_api_key.target_cluster-sa-kafka-api-key.id
    secret = confluent_api_key.target_cluster-sa-kafka-api-key.secret
  }

  depends_on = [ confluent_kafka_cluster.target_kafka-cluster, confluent_service_account.target_cluster-sa ]
}

resource "confluent_kafka_topic" "connect_replicator_internal_offsets-topic" { 
  kafka_cluster {
    id = confluent_kafka_cluster.target_kafka-cluster.id
  }
  rest_endpoint = confluent_kafka_cluster.target_kafka-cluster.rest_endpoint

  topic_name         = "connect-replicator-offsets"
  partitions_count   = 5
  config = {
    "cleanup.policy"      = "compact"
  }
  
  credentials {    
    key    = confluent_api_key.target_cluster-sa-kafka-api-key.id
    secret = confluent_api_key.target_cluster-sa-kafka-api-key.secret
  }

  depends_on = [ confluent_kafka_cluster.target_kafka-cluster, confluent_service_account.target_cluster-sa ]
}

resource "confluent_kafka_topic" "connect_replicator_internal_status-topic" { 
  kafka_cluster {
    id = confluent_kafka_cluster.target_kafka-cluster.id
  }
  rest_endpoint = confluent_kafka_cluster.target_kafka-cluster.rest_endpoint

  topic_name         = "connect-replicator-status"
  partitions_count   = 5
  config = {
    "cleanup.policy"      = "compact"
  }
  
  credentials {
    key    = confluent_api_key.target_cluster-sa-kafka-api-key.id
    secret = confluent_api_key.target_cluster-sa-kafka-api-key.secret
  }

  depends_on = [ confluent_kafka_cluster.target_kafka-cluster, confluent_service_account.target_cluster-sa ]
}

## NOTE: DeveloperWrite access is needed if not ClusterOwner
resource "confluent_kafka_topic" "connect_replicator_internal_monitoring-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.target_kafka-cluster.id
  }
  rest_endpoint = confluent_kafka_cluster.target_kafka-cluster.rest_endpoint

  topic_name         = "_confluent-monitoring"
  partitions_count   = 5
  config = {
    "cleanup.policy"      = "compact"
  }
  
  credentials {    
    key    = confluent_api_key.target_cluster-sa-kafka-api-key.id
    secret = confluent_api_key.target_cluster-sa-kafka-api-key.secret
  }

  depends_on = [ confluent_kafka_cluster.target_kafka-cluster, confluent_service_account.target_cluster-sa ]
}

### SCHEMA REGISTRY ESSENTIALS PACKAGE ON THE TARGET CLUSTER
data "confluent_schema_registry_region" "sr-gcp-region" {
  cloud   = "GCP"
  region  = "europe-west3"
  package = "ESSENTIALS"
}

resource "confluent_schema_registry_cluster" "target_sr" {
  package = data.confluent_schema_registry_region.sr-gcp-region.package

  environment {
    id = confluent_environment.target_environment.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    # Schema Registry and Kafka clusters can be in different regions as well as different cloud providers,
    # but you should to place both in the same cloud and region to restrict the fault isolation boundary.
    id = data.confluent_schema_registry_region.sr-gcp-region.id
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
  depends_on = [ confluent_kafka_cluster.target_kafka-cluster ]
}

### SR API KEY
resource "confluent_api_key" "target_schema-registry-api-key" {
  display_name = "target_cluster-manager-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by '${confluent_service_account.target_cluster-sa.display_name}' service account"
  owner {
    id          = confluent_service_account.target_cluster-sa.id
    api_version = confluent_service_account.target_cluster-sa.api_version
    kind        = confluent_service_account.target_cluster-sa.kind
  }

  managed_resource {
    id          = confluent_schema_registry_cluster.target_sr.id
    api_version = confluent_schema_registry_cluster.target_sr.api_version
    kind        = confluent_schema_registry_cluster.target_sr.kind

    environment {
      id =  confluent_environment.target_environment.id
    }
  }
  depends_on = [ confluent_schema_registry_cluster.target_sr ]
}