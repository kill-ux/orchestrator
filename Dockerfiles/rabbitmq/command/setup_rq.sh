#!/bin/sh
set -euo pipefail
rabbitmq-server &
TEMP_PID=$!

echo "Waiting for RabbitMQ to become fully responsive..."
rabbitmqctl wait --timeout 15 /var/lib/rabbitmq/mnesia/rabbit@$HOSTNAME.pid

rabbitmqctl add_user $RABBITMQ_USER $RABBITMQ_PASS || true
rabbitmqctl set_permissions -p / $RABBITMQ_USER ".*" ".*" ".*" || true

service rabbitmq-server stop
wait $TEMP_PID

exec rabbitmq-server