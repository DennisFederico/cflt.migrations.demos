# Running replicator using Docker Compose

1. First Run Terraform to create the environments
2. Use the output to modify the `config.env` file
3. Source the file `set -a; source config.env; set +a` to load the variable before running docker compose
4. Start Replicate `docker compose up`

docker compose --env-file ./config.env


ABOUT OFFSET TRANSLATION
https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/replicator-failover.html#understanding-consumer-offset-translation

https://docs.confluent.io/platform/current/multi-dc-deployments/replicator/replicator-failover.html#advanced-configuration-for-failover-scenarios-tuning-offset-translation

## Some commands

1. Test Connection (TODO: TERRAFORM TO PREPARE PROPERTIES AND GREP VALUE OF FIRST LINE FOR BOOTSTRAP?)
`kafka-topics --bootstrap-server pkc-4r297.europe-west1.gcp.confluent.cloud:9092 --command-config source-cluster.properties --list`
`kafka-topics --bootstrap-server pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092 --command-config target-cluster.properties --list`

2. PRODUCE DATA
`kafka-console-producer --bootstrap-server pkc-4r297.europe-west1.gcp.confluent.cloud:9092 --producer.config source-cluster.properties --topic source.topic.2`

3. CONSUME DATA
`kafka-console-consumer --bootstrap-server pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092 --consumer.config target-cluster.properties --topic source.topic.1 --from-beginning`


4. MANAGE CONNECTOR
`curl -X DELETE http://localhost:8083/connectors/replicator-demo`

`curl -s -X GET http://localhost:8083/connectors/replicator-demo/status | jq`


$curl -s "http://localhost:8083/connectors/replicator-demo/status" | jq '.tasks [0].trace' | sed 's/\\n/\n/g; s/\lt/\t/g'


LIST CURRENT LOGGER CONFIG

$curl -s http://localhost:8083/admin/loggers/ | jq
{
"'org.apache.kafka.connect.runtime.rest":{
"level": "WARN"
§ g
"org.reflections"': {
"level": "ERROR"
"'root": §
"level": "INFO"
}
}

MODIFY LOGGER
curl -s -X PUT -H "Content-Type:application/json"' \
http://localhost:8083/admin/loggers/io.confluent.connect.jdbc|
-d '{"level": "TRACE"}'