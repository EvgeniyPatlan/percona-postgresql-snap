#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_DATA/etc/pgpool
mkdir -p $SNAP_COMMON/var/log/pgpool
mkdir -p $SNAP_DATA/var/run/pgpool

# Set up pgpool configuration
PGPOOL_CONFIG=${PGPOOL_CONFIG:-$SNAP_DATA/etc/pgpool/pgpool.conf}

if [ ! -f "$PGPOOL_CONFIG" ]; then
    # Copy default config and customize
    cp $SNAP/etc/pgpool.conf $PGPOOL_CONFIG
    
    # Update paths in configuration
    sed -i "s|/var/snap/percona-postgresql/current|$SNAP_DATA|g" $PGPOOL_CONFIG
    sed -i "s|/var/snap/percona-postgresql/common|$SNAP_COMMON|g" $PGPOOL_CONFIG
fi

# Start pgpool-II
echo "Starting pgpool-II with config: $PGPOOL_CONFIG"
exec $SNAP/usr/sbin/pgpool -n -f "$PGPOOL_CONFIG"