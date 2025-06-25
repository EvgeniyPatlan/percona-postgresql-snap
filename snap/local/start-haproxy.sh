#!/bin/bash

set -e

# Set up environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP_COMMON=${SNAP_COMMON:-/var/snap/percona-postgresql/common}

# Create necessary directories
mkdir -p $SNAP_DATA/etc/haproxy
mkdir -p $SNAP_COMMON/var/log/haproxy
mkdir -p $SNAP_DATA/var/run/haproxy

# Set up HAProxy configuration
HAPROXY_CONFIG=${HAPROXY_CONFIG:-$SNAP_DATA/etc/haproxy/haproxy.cfg}

if [ ! -f "$HAPROXY_CONFIG" ]; then
    # Copy default config and customize
    cp $SNAP/etc/haproxy.cfg $HAPROXY_CONFIG
    
    # Update paths in configuration if needed
    sed -i "s|TLS_CERT_PATH|$SNAP_DATA/tls/server.crt|g" $HAPROXY_CONFIG
fi

# Start HAProxy
echo "Starting HAProxy with config: $HAPROXY_CONFIG"
exec $SNAP/usr/sbin/haproxy -f "$HAPROXY_CONFIG" -D