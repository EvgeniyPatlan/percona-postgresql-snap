#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_COMMON/var/log/exporters

# PgBouncer connection parameters
export PGBOUNCER_EXPORTER_HOST="${PGBOUNCER_EXPORTER_HOST:-localhost}"
export PGBOUNCER_EXPORTER_PORT="${PGBOUNCER_EXPORTER_PORT:-6432}"
export PGBOUNCER_EXPORTER_USER="${PGBOUNCER_EXPORTER_USER:-postgres}"
export PGBOUNCER_EXPORTER_PASS="${PGBOUNCER_EXPORTER_PASS:-postgres}"
export PGBOUNCER_EXPORTER_WEB_LISTEN_ADDRESS="${PGBOUNCER_EXPORTER_WEB_LISTEN_ADDRESS:-:9127}"

# Start PgBouncer exporter
echo "Starting PgBouncer Prometheus exporter on $PGBOUNCER_EXPORTER_WEB_LISTEN_ADDRESS"
exec $SNAP/usr/bin/pgbouncer_exporter \
    --web.listen-address="$PGBOUNCER_EXPORTER_WEB_LISTEN_ADDRESS" \
    --pgBouncer.connectionString="postgresql://$PGBOUNCER_EXPORTER_USER:$PGBOUNCER_EXPORTER_PASS@$PGBOUNCER_EXPORTER_HOST:$PGBOUNCER_EXPORTER_PORT/pgbouncer?sslmode=disable"