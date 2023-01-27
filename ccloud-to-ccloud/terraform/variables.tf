variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "source_environment_name" {
  description = "Name of Source environment"
  type        = string
  sensitive   = false
}

variable "target_environment_name" {
  description = "Name of Target environment"
  type        = string
  sensitive   = false
}

variable "source_kafka_cluster_name" {
  description = "Source Cluster Name"
  type        = string
  sensitive   = false
}

variable "target_kafka_cluster_name" {
  description = "Target Cluster Name"
  type        = string
  sensitive   = false
}

variable "source_topics" {
  description = "List of topics to create"
  type        = list(string)
  sensitive   = false  
}

variable "replicator_consumer_group_prefix" {
  description = "Prefix of the replicator consumer group"  
  type        = string
  default     = "replicator-demo"
  sensitive   = false  
}

variable "topics_partition" {
  description = "Topics Partition"
  default = 6
}

variable "source_replicator_topic-prefixes" {
  description = "Topic Prefixes of the topics to grant read access"
  type        = list(string)
  sensitive   = false
}