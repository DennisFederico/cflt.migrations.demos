# Running replicator using Docker Compose

1. First Run Terraform to create the environments
2. Use the output to modify the `config.env` file
3. Source the file `set -a; source config.env; set +a` to load the variable before running docker compose
4. Start Replicate `docker compose up`

docker compose --env-file ./config.env


## Some commands

1. TODO -> Convert .env to properties for both Source and Target cluster
2. Test Connection
`kafka-topics --bootstrap-server pkc-4r297.europe-west1.gcp.confluent.cloud:9092 --command-config source-cluster.properties --list`

`kafka-topics --bootstrap-server pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092 --command-config target-cluster.properties --list`

`kafka-console-producer --bootstrap-server pkc-4r297.europe-west1.gcp.confluent.cloud:9092 --producer.config source-cluster.properties --topic source.topic.2`

`kafka-console-consumer --bootstrap-server pkc-l6wr6.europe-west2.gcp.confluent.cloud:9092 --consumer.config target-cluster.properties --topic source.topic.1 --from-beginning`

`curl -s -X GET http://localhost:8083/connectors/replicator-topic2/status | jq`

`curl -X DELETE http://localhost:8083/connectors/<connector-name>`
