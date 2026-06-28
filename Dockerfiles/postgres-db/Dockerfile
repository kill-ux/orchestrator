FROM debian:stable-slim

RUN apt-get update && \ 
    apt-get install -y --no-install-recommends postgresql && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=postgres:postgres command/setup_db.sh /tmp/setup_db.sh
RUN chmod +x /tmp/setup_db.sh

ENTRYPOINT [ "bash", "/tmp/setup_db.sh" ]
