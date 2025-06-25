#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_COMMON/var/log/exporters

# pgBackRest exporter parameters
export PGBACKREST_EXPORTER_CONFIG_FILE="${PGBACKREST_EXPORTER_CONFIG_FILE:-$SNAP_DATA/etc/pgbackrest/pgbackrest.conf}"
export PGBACKREST_EXPORTER_WEB_LISTEN_ADDRESS="${PGBACKREST_EXPORTER_WEB_LISTEN_ADDRESS:-:9854}"
export PGBACKREST_EXPORTER_WEB_TELEMETRY_PATH="${PGBACKREST_EXPORTER_WEB_TELEMETRY_PATH:-/metrics}"

# Start pgBackRest exporter
echo "Starting pgBackRest Prometheus exporter on $PGBACKREST_EXPORTER_WEB_LISTEN_ADDRESS"
exec $SNAP/usr/bin/pgbackrest_exporter \
    --web.listen-address="$PGBACKREST_EXPORTER_WEB_LISTEN_ADDRESS" \
    --web.telemetry-path="$PGBACKREST_EXPORTER_WEB_TELEMETRY_PATH" \
    --pgbackrest.config-file="$PGBACKREST_EXPORTER_CONFIG_FILE"