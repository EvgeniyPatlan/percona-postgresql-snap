#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_COMMON/var/log/exporters

# PostgreSQL connection parameters
export DATA_SOURCE_NAME="${DATA_SOURCE_NAME:-postgresql://postgres:postgres@localhost:5432/postgres?sslmode=disable}"
export PG_EXPORTER_WEB_LISTEN_ADDRESS="${PG_EXPORTER_WEB_LISTEN_ADDRESS:-:9187}"
export PG_EXPORTER_WEB_TELEMETRY_PATH="${PG_EXPORTER_WEB_TELEMETRY_PATH:-/metrics}"

# Start PostgreSQL exporter
echo "Starting PostgreSQL Prometheus exporter on $PG_EXPORTER_WEB_LISTEN_ADDRESS"
exec $SNAP/usr/bin/postgres_exporter \
    --web.listen-address="$PG_EXPORTER_WEB_LISTEN_ADDRESS" \
    --web.telemetry-path="$PG_EXPORTER_WEB_TELEMETRY_PATH"