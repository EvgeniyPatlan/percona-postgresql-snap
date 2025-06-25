#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_DATA/etc/pgbouncer
mkdir -p $SNAP_COMMON/var/log/pgbouncer
mkdir -p $SNAP_DATA/var/run/pgbouncer

# Set up PgBouncer configuration
PGBOUNCER_CONFIG=${PGBOUNCER_CONFIG:-$SNAP_DATA/etc/pgbouncer/pgbouncer.ini}

if [ ! -f "$PGBOUNCER_CONFIG" ]; then
    # Copy default config and customize
    cp $SNAP/etc/pgbouncer.ini $PGBOUNCER_CONFIG
    cp $SNAP/etc/userlist.txt $SNAP_DATA/etc/pgbouncer/userlist.txt
    
    # Update paths in configuration
    sed -i "s|AUTH_FILE_PATH|$SNAP_DATA/etc/pgbouncer/userlist.txt|g" $PGBOUNCER_CONFIG
    sed -i "s|LOGFILE_PATH|$SNAP_COMMON/var/log/pgbouncer/pgbouncer.log|g" $PGBOUNCER_CONFIG
    sed -i "s|PIDFILE_PATH|$SNAP_DATA/var/run/pgbouncer/pgbouncer.pid|g" $PGBOUNCER_CONFIG
fi

# Start PgBouncer
echo "Starting PgBouncer with config: $PGBOUNCER_CONFIG"
exec $SNAP/usr/sbin/pgbouncer "$PGBOUNCER_CONFIG"