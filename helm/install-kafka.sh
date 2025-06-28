helm install kafka bitnami/kafka \
  --namespace linkshortener \
  --set replicaCount=1 \
  --set zookeeper.enabled=true \
  --set auth.enabled=false \
  --set listeners.client.protocol=PLAINTEXT \
  --set listeners.client.port=9092 \
  --set extraEnvVars[0].name=KAFKA_CFG_ADVERTISED_LISTENERS \
  --set extraEnvVars[0].value=PLAINTEXT://kafka.linkshortener.svc.cluster.local:9092
