for d in api-gateway postgres-db billing-app inventory-app rabbitmq; do
    docker build -t killux3k/$d/v1.0.0 $d;
done