#!/bin/bash

set -e

export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}
export PGDATA="$SNAP_COMMON/var/lib/postgresql/17/main"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"

# Ensure required directories exist
mkdir -p "$PGDATA"
mkdir -p "$SNAP_COMMON/var/log/postgresql"
mkdir -p "$SNAP_DATA/etc/postgresql"
chown -R snap_daemon:snap_daemon "$SNAP_COMMON/var/lib/postgresql/17"
chown -R snap_daemon:snap_daemon "$SNAP_COMMON/var/log/postgresql"
chmod 755 "$SNAP_COMMON/var/log/postgresql"
chmod 700 "$PGDATA"

# Initialize database cluster if it doesn't exist
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Initializing PostgreSQL cluster as snap_daemon..."

    pwfile="$SNAP_COMMON/tmp-pg-pass"
    mkdir -p "$(dirname "$pwfile")"
    echo "${POSTGRES_PASSWORD:-postgres}" > "$pwfile"
    chmod 600 "$pwfile"
    chown snap_daemon:snap_daemon "$pwfile"

    runuser -u snap_daemon -- \
        "$SNAP/usr/lib/postgresql/17/bin/initdb" \
        -D "$PGDATA" \
        --auth-local=md5 \
        --auth-host=md5 \
        --username=postgres \
        --pwfile="$pwfile" \
        --encoding=UTF8 \
        --locale=C.UTF-8

    rm -f "$pwfile"

    # PostgreSQL main config
    runuser -u snap_daemon -- tee -a "$PGDATA/postgresql.conf" > /dev/null <<EOF
listen_addresses = '*'
port = $PGPORT
unix_socket_directories = '/tmp'
log_directory = '$SNAP_COMMON/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
logging_collector = on
shared_buffers = 128MB
max_connections = 100
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
EOF

    # HBA (authentication) config
    runuser -u snap_daemon -- tee -a "$PGDATA/pg_hba.conf" > /dev/null <<EOF
host    all             all             0.0.0.0/0               md5
host    replication     all             0.0.0.0/0               md5
EOF
fi

echo "Starting PostgreSQL as snap_daemon..."
exec runuser -u snap_daemon -- \
    "$SNAP/usr/lib/postgresql/17/bin/postgres" \
    -D "$PGDATA" \
    -c config_file="$PGDATA/postgresql.conf"

