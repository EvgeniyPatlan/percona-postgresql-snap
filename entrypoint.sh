#!/bin/bash
set -e

# Function to wait for a service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local timeout=${3:-30}
    
    echo "Waiting for $host:$port to be ready..."
    for i in $(seq 1 $timeout); do
        if nc -z $host $port 2>/dev/null; then
            echo "$host:$port is ready!"
            return 0
        fi
        sleep 1
    done
    echo "Timeout waiting for $host:$port"
    return 1
}

# Initialize environment
export SNAP_DATA=${SNAP_DATA:-/var/snap/percona-postgresql/current}
export SNAP=${SNAP:-/snap/percona-postgresql/current}

# Create necessary directories
mkdir -p $SNAP_DATA/{postgresql,patroni,logs,tls}

# Initialize PostgreSQL if not already done
if [ ! -f "$SNAP_DATA/postgresql/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database..."
    $SNAP/bin/initdb -D $SNAP_DATA/postgresql \
        --auth-local=md5 \
        --auth-host=md5 \
        --username=postgres \
        --pwfile=<(echo "${POSTGRES_PASSWORD:-postgres}")
    
    # Configure PostgreSQL
    cat >> $SNAP_DATA/postgresql/postgresql.conf << EOF
listen_addresses = '*'
port = 5432
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
EOF

    # Configure pg_hba.conf
    cat >> $SNAP_DATA/postgresql/pg_hba.conf << EOF
host replication all 0.0.0.0/0 md5
host all all 0.0.0.0/0 md5
EOF
fi

# Copy configuration files if they don't exist
if [ ! -f "$SNAP_DATA/patroni.yml" ]; then
    cp $SNAP/configs/patroni1.yml $SNAP_DATA/patroni.yml
    # Update configuration paths
    sed -i "s|DATA_DIR|$SNAP_DATA/postgresql|g" $SNAP_DATA/patroni.yml
    sed -i "s|BIN_DIR|$SNAP/bin|g" $SNAP_DATA/patroni.yml
    sed -i "s|CLUSTER_NAME|${PATRONI_CLUSTER_NAME:-percona-cluster}|g" $SNAP_DATA/patroni.yml
    sed -i "s|NODE_NAME|${PATRONI_NODE_NAME:-$(hostname)}|g" $SNAP_DATA/patroni.yml
    sed -i "s|ETCD_HOSTS|${ETCD_HOSTS:-127.0.0.1:2379}|g" $SNAP_DATA/patroni.yml
fi

if [ ! -f "$SNAP_DATA/haproxy.cfg" ]; then
    cp $SNAP/configs/haproxy.cfg $SNAP_DATA/haproxy.cfg
fi

if [ ! -f "$SNAP_DATA/pgbouncer.ini" ]; then
    cp $SNAP/configs/pgbouncer.ini $SNAP_DATA/pgbouncer.ini
    cp $SNAP/configs/userlist.txt $SNAP_DATA/userlist.txt
    # Update configuration paths
    sed -i "s|AUTH_FILE_PATH|$SNAP_DATA/userlist.txt|g" $SNAP_DATA/pgbouncer.ini
    sed -i "s|LOGFILE_PATH|$SNAP_DATA/logs/pgbouncer.log|g" $SNAP_DATA/pgbouncer.ini
    sed -i "s|PIDFILE_PATH|$SNAP_DATA/pgbouncer.pid|g" $SNAP_DATA/pgbouncer.ini
fi

# Set up TLS certificates if provided
if [ -n "$TLS_CERT" ] && [ -n "$TLS_KEY" ]; then
    echo "$TLS_CERT" > $SNAP_DATA/tls/server.crt
    echo "$TLS_KEY" > $SNAP_DATA/tls/server.key
    echo "${TLS_CA:-$TLS_CERT}" > $SNAP_DATA/tls/ca.crt
    chmod 600 $SNAP_DATA/tls/server.key
    chmod 644 $SNAP_DATA/tls/server.crt $SNAP_DATA/tls/ca.crt
    
    # Enable TLS in PostgreSQL
    cat >> $SNAP_DATA/postgresql/postgresql.conf << EOF
ssl = on
ssl_cert_file = '$SNAP_DATA/tls/server.crt'
ssl_key_file = '$SNAP_DATA/tls/server.key'
ssl_ca_file = '$SNAP_DATA/tls/ca.crt'
EOF
fi

# Handle different startup modes
case "${1:-standalone}" in
    "standalone")
        echo "Starting PostgreSQL in standalone mode..."
        exec $SNAP/bin/postgres -D $SNAP_DATA/postgresql
        ;;
    
    "patroni")
        echo "Starting Patroni cluster node..."
        # Wait for etcd if specified
        if [ -n "$ETCD_HOSTS" ]; then
            IFS=',' read -ra ETCD_ARRAY <<< "$ETCD_HOSTS"
            for etcd_host in "${ETCD_ARRAY[@]}"; do
                host=$(echo $etcd_host | cut -d':' -f1)
                port=$(echo $etcd_host | cut -d':' -f2)
                wait_for_service $host $port
            done
        fi
        exec python3 -m patroni $SNAP_DATA/patroni.yml
        ;;
    
    "haproxy")
        echo "Starting HAProxy load balancer..."
        exec haproxy -f $SNAP_DATA/haproxy.cfg -D
        ;;
    
    "pgbouncer")
        echo "Starting PgBouncer connection pooler..."
        exec pgbouncer $SNAP_DATA/pgbouncer.ini
        ;;
    
    "cluster")
        echo "Starting full cluster stack..."
        
        # Start PostgreSQL with Patroni
        python3 -m patroni $SNAP_DATA/patroni.yml &
        PATRONI_PID=$!
        
        # Wait for PostgreSQL to be ready
        wait_for_service 127.0.0.1 5432
        
        # Start PgBouncer
        pgbouncer $SNAP_DATA/pgbouncer.ini &
        PGBOUNCER_PID=$!
        
        # Start HAProxy
        haproxy -f $SNAP_DATA/haproxy.cfg -D &
        HAPROXY_PID=$!
        
        # Wait for any process to exit
        wait $PATRONI_PID $PGBOUNCER_PID $HAPROXY_PID
        ;;
    
    *)
        echo "Usage: $0 {standalone|patroni|haproxy|pgbouncer|cluster}"
        echo ""
        echo "Environment variables:"
        echo "  POSTGRES_PASSWORD    - PostgreSQL superuser password"
        echo "  PATRONI_CLUSTER_NAME - Patroni cluster name"
        echo "  PATRONI_NODE_NAME    - Patroni node name"
        echo "  ETCD_HOSTS          - Comma-separated etcd hosts"
        echo "  TLS_CERT            - TLS certificate content"
        echo "  TLS_KEY             - TLS private key content"
        echo "  TLS_CA              - TLS CA certificate content"
        exit 1
        ;;
esac
