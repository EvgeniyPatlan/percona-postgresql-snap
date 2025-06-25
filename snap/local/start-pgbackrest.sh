#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_DATA/etc/pgbackrest
mkdir -p $SNAP_COMMON/var/log/pgbackrest
mkdir -p $SNAP_COMMON/var/lib/pgbackrest
mkdir -p $SNAP_DATA/var/run/pgbackrest

# Set up pgBackRest configuration
PGBACKREST_CONFIG=${PGBACKREST_CONFIG:-$SNAP_DATA/etc/pgbackrest/pgbackrest.conf}

if [ ! -f "$PGBACKREST_CONFIG" ]; then
    # Copy default config and customize
    cp $SNAP/etc/pgbackrest.conf $PGBACKREST_CONFIG
    
    # Update paths in configuration
    sed -i "s|/var/snap/percona-postgresql/current|$SNAP_DATA|g" $PGBACKREST_CONFIG
    sed -i "s|/var/snap/percona-postgresql/common|$SNAP_COMMON|g" $PGBACKREST_CONFIG
fi

# Set pgBackRest environment
export PGBACKREST_CONFIG

# Start pgBackRest server mode
echo "Starting pgBackRest server with config: $PGBACKREST_CONFIG"
exec $SNAP/usr/bin/pgbackrest --config="$PGBACKREST_CONFIG" server