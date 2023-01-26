output "resources-data" {
  value = <<-EOT
  Source Environment:   ${confluent_environment.source_environment.display_name} (${confluent_environment.source_environment.id})
  Source Kafka Cluster: ${confluent_kafka_cluster.source_kafka-cluster.display_name} (${confluent_kafka_cluster.source_kafka-cluster.id})
  Source Cluster Owner Service Account:
  ${confluent_service_account.source_cluster-sa.display_name}: ${confluent_service_account.source_cluster-sa.id}
  ${confluent_service_account.source_cluster-sa.display_name}'s Kafka API Key:     "${confluent_api_key.source_cluster-sa-kafka-api-key.id}"
  ${confluent_service_account.source_cluster-sa.display_name}'s Kafka API Secret:  "${nonsensitive(confluent_api_key.source_cluster-sa-kafka-api-key.secret)}"
  ---
  Target Environment:   ${confluent_environment.target_environment.display_name}(${confluent_environment.target_environment.id})
  Target Kafka Cluster: ${confluent_kafka_cluster.target_kafka-cluster.display_name} (${confluent_kafka_cluster.target_kafka-cluster.id})
  Target Cluster Owner Service Account:
  ${confluent_service_account.target_cluster-sa.display_name}: ${confluent_service_account.target_cluster-sa.id}
  ${confluent_service_account.target_cluster-sa.display_name}'s Kafka API Key:     "${confluent_api_key.target_cluster-sa-kafka-api-key.id}"
  ${confluent_service_account.target_cluster-sa.display_name}'s Kafka API Secret:  "${nonsensitive(confluent_api_key.target_cluster-sa-kafka-api-key.secret)}"

  Target SCHEMA REGISTRY Endpoint: ${confluent_schema_registry_cluster.target_sr.rest_endpoint}
  API-KEY: ${confluent_api_key.target_schema-registry-api-key.id}
  SECRET: ${confluent_api_key.target_schema-registry-api-key.secret}
  ---
  Replicator:
  Replicator SOURCE Bootstrap: ${confluent_kafka_cluster.source_kafka-cluster.bootstrap_endpoint}
  Replicator SOURCE API Key: '${confluent_api_key.source_replicator-sa-kafka-api-key.id}'
  Replicator SOURCE API Secret: '${nonsensitive(confluent_api_key.source_replicator-sa-kafka-api-key.secret)}'

  Replicator TARGET Bootstrap: ${confluent_kafka_cluster.target_kafka-cluster.bootstrap_endpoint}
  Replicator TARGET API Key: '${confluent_api_key.target_cluster-sa-kafka-api-key.id}'
  Replicator TARGET API Secret: '${nonsensitive(confluent_api_key.target_cluster-sa-kafka-api-key.secret)}'
  EOT
  sensitive = true
}