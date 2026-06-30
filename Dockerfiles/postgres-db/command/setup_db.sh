#!/bin/sh
set -euo pipefail

export PGDATA=/var/lib/postgresql/main

if [ -z ${DB_USER:-} ] || [ -z ${DB_PASS:-} ] || [ -z ${DB_NAME:-} ]; then
    echo "ERROR: DB_USER, DB_PASS, and DB_NAME environment variables must be set!"
    exit 1
fi

PG_VERSION=$(ls /usr/lib/postgresql | grep -E '^[0-9]+$')
PG_BIN="/usr/lib/postgresql/$PG_VERSION/bin"

echo "check fils inside $PGDATA"
ls $PGDATA

if [ ! -d "$PGDATA/base" ]; then
    mkdir -p "$PGDATA"
    chown -R postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"

    echo "Initializing database storage..."
    su postgres -c "$PG_BIN/initdb -D '$PGDATA'"

    echo "Configuring authentication..."
    cat > "$PGDATA/pg_hba.conf" << EOF
local all all trust
host all all 0.0.0.0/0 scram-sha-256
EOF

    echo "Starting temporary cluster for setup..."
    su postgres -c "$PG_BIN/pg_ctl -D '$PGDATA' -w start"

    echo "Configuring roles and databases..."
    su postgres -c "$PG_BIN/psql -d postgres -c \"ALTER USER postgres WITH PASSWORD '$DB_PASS';\""
    su postgres -c "$PG_BIN/psql -d postgres -c \"CREATE USER $DB_USER WITH SUPERUSER PASSWORD '$DB_PASS';\""
    su postgres -c "$PG_BIN/createdb -O $DB_USER $DB_NAME"

    echo "Shutting down temporary setup cluster..."
    su postgres -c "$PG_BIN/pg_ctl -D '$PGDATA' -m fast stop"
fi

echo "Starting PostgreSQL in the foreground..."
exec su postgres -c "$PG_BIN/postgres -D '$PGDATA' -h '*'"