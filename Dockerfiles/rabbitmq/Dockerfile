FROM debian:stable-slim

RUN apt-get update && \ 
    apt-get install -y --no-install-recommends rabbitmq-server && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 5672

COPY command/setup_rq.sh /tmp/setup_rq.sh

RUN chmod +x /tmp/setup_rq.sh

ENTRYPOINT [ "bash", "/tmp/setup_rq.sh" ]