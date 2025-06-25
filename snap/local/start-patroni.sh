#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_DATA/etc/patroni
mkdir -p $SNAP_COMMON/var/log/patroni
mkdir -p $SNAP_COMMON/var/lib/postgresql/17/main

# Set up Patroni configuration
PATRONI_CONFIG_FILE=${PATRONI_CONFIG_FILE:-$SNAP_DATA/etc/patroni/patroni.yml}

if [ ! -f "$PATRONI_CONFIG_FILE" ]; then
    # Copy default config and customize
    cp $SNAP/etc/patroni1.yml $PATRONI_CONFIG_FILE
    
    # Update paths in configuration
    sed -i "s|DATA_DIR|$SNAP_COMMON/var/lib/postgresql/17/main|g" $PATRONI_CONFIG_FILE
    sed -i "s|BIN_DIR|$SNAP/usr/lib/postgresql/17/bin|g" $PATRONI_CONFIG_FILE
    sed -i "s|CLUSTER_NAME|${PATRONI_CLUSTER_NAME:-percona-cluster}|g" $PATRONI_CONFIG_FILE
    sed -i "s|NODE_NAME|${PATRONI_NODE_NAME:-$(hostname)}|g" $PATRONI_CONFIG_FILE
    sed -i "s|ETCD_HOSTS|${ETCD_HOSTS:-127.0.0.1:2379}|g" $PATRONI_CONFIG_FILE
fi

# Set Patroni environment
export PATRONI_CONFIG_FILE

# Initialize PostgreSQL data directory if needed
PGDATA="$SNAP_COMMON/var/lib/postgresql/17/main"
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database cluster..."
    $SNAP/usr/lib/postgresql/17/bin/initdb \
        -D "$PGDATA" \
        --auth-local=md5 \
        --auth-host=md5 \
        --username=postgres \
        --pwfile=<(echo "${POSTGRES_PASSWORD:-postgres}")
    
    # Set proper permissions
    chmod 700 "$PGDATA"
fi

# Start Patroni
echo "Starting Patroni with config: $PATRONI_CONFIG_FILE"
exec $SNAP/usr/bin/patroni "$PATRONI_CONFIG_FILE"
