output "kafka-resources-data" {
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
  ---
  Target SCHEMA REGISTRY Endpoint: ${confluent_schema_registry_cluster.target_sr.rest_endpoint}
  API-KEY: ${confluent_api_key.target_schema-registry-api-key.id}
  SECRET: ${nonsensitive(confluent_api_key.target_schema-registry-api-key.secret)}
  ---
  Replicator:
  Replicator SOURCE Bootstrap: ${confluent_kafka_cluster.source_kafka-cluster.bootstrap_endpoint}
  Replicator SOURCE API Key: '${confluent_api_key.source_replicator-sa-kafka-api-key.id}'
  Replicator SOURCE API Secret: '${nonsensitive(confluent_api_key.source_replicator-sa-kafka-api-key.secret)}'

  Replicator TARGET Bootstrap: ${confluent_kafka_cluster.target_kafka-cluster.bootstrap_endpoint}
  Replicator TARGET API Key: '${confluent_api_key.target_cluster-sa-kafka-api-key.id}'
  Replicator TARGET API Secret: '${nonsensitive(confluent_api_key.target_cluster-sa-kafka-api-key.secret)}'
  EOT
  sensitive = false
}

output "submit-replicator_sh" {
  value = <<-EOT
  #!/bin/bash"
  HEADER="Content-Type: application/json"
  DATA=$( cat << EOF
  {
    "name": "replicator-demo",
    "config": {
      "name": "replicator-demo",
      "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
      "tasks.max": "1",
      "topic.whitelist": "source.topic.2",
      "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
      "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
      "topic.auto.create": "true",
      "topic.preserve.partitions": "true",

      "src.kafka.bootstrap.servers": "${confluent_kafka_cluster.source_kafka-cluster.bootstrap_endpoint}",
      "src.kafka.security.protocol": "SASL_SSL",
      "src.kafka.sasl.mechanism": "PLAIN",
      "src.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.source_replicator-sa-kafka-api-key.id}' password='${nonsensitive(confluent_api_key.source_replicator-sa-kafka-api-key.secret)}';",
      "src.consumer.group.id": "replicator-demo",

      "dest.kafka.bootstrap.servers": "${confluent_kafka_cluster.target_kafka-cluster.bootstrap_endpoint}",
      "dest.kafka.security.protocol": "SASL_SSL",
      "dest.kafka.sasl.mechanism": "PLAIN",
      "dest.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.target_cluster-sa-kafka-api-key.id}' password='${nonsensitive(confluent_api_key.target_cluster-sa-kafka-api-key.secret)}';"
    }
  }
  EOF
  )
  curl -X POST -H "$${HEADER}" --data "$${DATA}" http://localhost:8083/connectors
  EOT
  sensitive = true
}

output "compose_env" {
  value = <<-EOT
#### VARIABLES FOR DOCKER COMPOSE
REPOSITORY=confluentinc
CONFLUENT_DOCKER_TAG=7.3.1-1-ubi8
SOURCE_CLUSTER_BOOTSTRAP=${confluent_kafka_cluster.source_kafka-cluster.bootstrap_endpoint}
SOURCE_CLUSTER_REST_URL=${confluent_kafka_cluster.source_kafka-cluster.rest_endpoint}
SOURCE_CLUSTER_OWNER_API_KEY=${confluent_api_key.source_cluster-sa-kafka-api-key.id}
SOURCE_CLUSTER_OWNER_API_SECRET=${nonsensitive(confluent_api_key.source_cluster-sa-kafka-api-key.secret)}
TARGET_CLUSTER_BOOTSTRAP=${confluent_kafka_cluster.target_kafka-cluster.bootstrap_endpoint}
TARGET_CLUSTER_REST_URL=${confluent_kafka_cluster.target_kafka-cluster.rest_endpoint}
TARGET_CLUSTER_OWNER_API_KEY=${confluent_api_key.target_cluster-sa-kafka-api-key.id}
TARGET_CLUSTER_OWNER_API_SECRET=${nonsensitive(confluent_api_key.target_cluster-sa-kafka-api-key.secret)}
TARGET_SCHEMA_REGISTRY_URL=${confluent_schema_registry_cluster.target_sr.rest_endpoint}
TARGET_SCHEMA_REGISTRY_API_KEY=${confluent_api_key.target_schema-registry-api-key.id}
TARGET_SCHEMA_REGISTRY_API_SECRET=${nonsensitive(confluent_api_key.target_schema-registry-api-key.secret)}
EOT
  sensitive = true
}

### KAFKA PROPERTIES FILE EXAMPLE
# bootstrap.servers=pkc-4r297.europe-west1.gcp.confluent.cloud:9092
# security.protocol=SASL_SSL
# sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='Y34CH54KH5Y6PV6M' password='3sN8tXjSMmK9GoL+v9poudUpyjiLtSTmdUEGbpFztp9mcACAbEarApjwtOS/HcIZ';
# sasl.mechanism=PLAIN
# # Required for correctness in Apache Kafka clients prior to 2.6
# client.dns.lookup=use_all_dns_ips
# # Best practice for higher availability in Apache Kafka clients prior to 3.0
# session.timeout.ms=45000
# # Best practice for Kafka producer to prevent data loss
# acks=all
# # Required connection configs for Confluent Cloud Schema Registry
# schema.registry.url=https://psrc-kk5gg.europe-west3.gcp.confluent.cloud
# basic.auth.credentials.source=USER_INFO
# basic.auth.user.info=VEXNQA6U2Y4QQYO3:Ivk1e2z5zlTS66LI5VqgiodxVDS65Tl4dJHNp5hIPsmzY7LWf+HZSN2bJWgEj0MO




