# Percona Distribution for PostgreSQL 17.5 Snap Package

This project provides a Snap package for Percona Distribution for PostgreSQL 17.5 with high availability features including Patroni, HAProxy, and PgBouncer.

## Features

* **PostgreSQL 17.5** : Latest Percona Distribution for PostgreSQL
* **High Availability** : Patroni cluster management with automatic failover
* **Load Balancing** : HAProxy for intelligent connection routing
* **Connection Pooling** : PgBouncer and pgpool-II for efficient connection management
* **Backup & Recovery** : pgBackRest enterprise-grade backup solution
* **Monitoring** : pgBadger log analysis, pg_gather diagnostics, and Prometheus exporters
* **Vector Database** : pgvector extension for AI/ML workloads
* **Security** : pgAudit and pgAudit set_user for comprehensive auditing
* **TLS Support** : Optional SSL/TLS encryption
* **Percona Toolkit** : Performance analysis and administrative tools
* **Container Support** : Docker and Docker Compose integration
* **Enterprise Architecture** : Following Canonical's best practices for snap packaging

## Architecture

This snap follows best practices for PostgreSQL packaging:

### **Directory Structure**

```
/var/snap/percona-postgresql/
├── current/                    # Current revision data
│   ├── etc/                   # Configuration files
│   │   ├── patroni/           # Patroni configurations
│   │   ├── pgbouncer/         # PgBouncer configurations
│   │   ├── haproxy/           # HAProxy configurations
│   │   ├── pgbackrest/        # pgBackRest configurations
│   │   └── pgpool/            # pgpool-II configurations
│   ├── var/run/               # Runtime files (PIDs, sockets)
│   └── tls/                   # TLS certificates
└── common/                    # Shared data across revisions
    ├── var/lib/postgresql/17/ # PostgreSQL data directory
    ├── var/log/               # Log files
    └── var/lib/pgbackrest/    # Backup repository
```

### **Layout Bindings**

* Proper Perl and Python library bindings
* PostgreSQL library paths correctly mapped
* Configuration directories bound to snap data
* Log access through content slots

### **System Integration**

* **Shared system user** : `snap_daemon` for secure operation
* **Memory management** : Private shared memory plugs
* **Network access** : Granular network and network-bind plugs
* **Process control** : Safe process management capabilities

### **Service Management**

All services use `install-mode: disable` allowing administrators to selectively enable components:

```bash
# Enable individual services
sudo snap start percona-postgresql.patroni
sudo snap start percona-postgresql.haproxy
sudo snap start percona-postgresql.pgbouncer-server
```

## Quick Start

### Install from Snap Store

```bash
sudo snap install percona-postgresql
```

### Build from Source

```bash
# Clone the repository
git clone <repository-url>
cd percona-postgresql-snap

# Build the snap
make build

# Install locally
make install
```

## Basic Usage

### Standalone PostgreSQL

```bash
# Start PostgreSQL service
sudo snap start percona-postgresql.postgresql

# Connect to database
percona-postgresql.psql -U postgres -h /tmp

# Check service status
sudo snap services percona-postgresql
```

### Configuration

### Snap Configuration Options

```bash
# Set PostgreSQL password
sudo snap set percona-postgresql postgres-password=secretpassword

# Configure Patroni cluster
sudo snap set percona-postgresql patroni-cluster-name=percona-cluster
sudo snap set percona-postgresql patroni-node-name=$(hostname)

# Configure etcd hosts
sudo snap set percona-postgresql etcd-hosts=127.0.0.1:2379

# Enable TLS
sudo snap set percona-postgresql enable-tls=true
```

### Configuration Files

All configuration files are stored in `/var/snap/percona-postgresql/current/`:

* `patroni.yml` - Patroni cluster configuration
* `haproxy.cfg` - HAProxy load balancer configuration
* `pgbouncer.ini` - PgBouncer connection pooler configuration
* `postgresql/postgresql.conf` - PostgreSQL server configuration

## Docker Usage

### Single Node

```bash
# Start with Docker Compose
docker-compose up -d

# Connect to PostgreSQL
docker-compose exec percona-postgresql percona-postgresql.psql -U postgres -h /tmp
```

### High Availability Cluster

```bash
# Start 3-node Patroni cluster
make compose-cluster

# Check cluster status
docker-compose exec percona-postgresql patronictl list

# Connect through HAProxy
psql -h localhost -p 5000 -U postgres
```

## Network Ports

| Service          | Port | Description                           |
| ---------------- | ---- | ------------------------------------- |
| PostgreSQL       | 5432 | Database connections                  |
| Patroni REST API | 8008 | Cluster management                    |
| HAProxy Primary  | 5000 | Load balanced primary connections     |
| HAProxy Replica  | 5001 | Load balanced replica connections     |
| HAProxy Stats    | 7000 | Statistics and monitoring             |
| PgBouncer        | 6432 | Connection pooling                    |
| pgpool-II        | 9999 | Connection pooling and load balancing |
| pgpool-II PCP    | 9898 | pgpool-II administration              |
| etcd             | 2379 | Cluster coordination                  |

## Commands Reference

### Available Snap Commands

```bash
# Core PostgreSQL
percona-postgresql.postgresql   # PostgreSQL server
percona-postgresql.psql         # PostgreSQL client
percona-postgresql.pg-dump      # Database backup utility
percona-postgresql.pg-restore   # Database restore utility
percona-postgresql.pg-dumpall   # Cluster-wide backup utility
percona-postgresql.pg-ctl       # PostgreSQL control utility
percona-postgresql.initdb       # Database initialization

# High Availability & Load Balancing
percona-postgresql.patroni      # Patroni cluster manager
percona-postgresql.patronictl   # Patroni control utility
percona-postgresql.haproxy      # HAProxy load balancer
percona-postgresql.pgbouncer    # PgBouncer connection pooler
percona-postgresql.pgpool2      # pgpool-II middleware

# Backup & Recovery
percona-postgresql.pgbackrest   # pgBackRest backup solution

# Monitoring & Analysis
percona-postgresql.pgbadger     # PostgreSQL log analyzer
percona-postgresql.pg-gather    # Diagnostic information collector

# Percona Toolkit
percona-postgresql.percona-toolkit # Main toolkit command
percona-postgresql.pt-summary      # System summary
percona-postgresql.pt-diskstats    # Disk statistics
```

### Makefile Commands

```bash
make build          # Build snap package
make install        # Install snap locally
make test           # Run basic tests
make start          # Start PostgreSQL service
make stop           # Stop all services
make status         # Show service status
make logs           # Show service logs
make connect        # Connect to PostgreSQL
make start-cluster  # Start Patroni cluster
make configure      # Configure snap options
make enable-tls     # Enable TLS support
make release        # Release to Snap Store
make help           # Show all available commands
```

## TLS Configuration

### Generate Certificates

```bash
# Create CA certificate
openssl genrsa -out ca.key 4096
openssl req -new -x509 -key ca.key -out ca.crt -days 3650

# Create server certificate
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -out server.crt -days 365

# Copy to snap directory
sudo cp ca.crt server.crt server.key /var/snap/percona-postgresql/current/tls/
sudo chmod 600 /var/snap/percona-postgresql/current/tls/server.key
```

### Enable TLS

```bash
# Enable TLS in snap configuration
sudo snap set percona-postgresql enable-tls=true

# Restart services
sudo snap restart percona-postgresql
```

## Troubleshooting

### Common Issues

1. **PostgreSQL won't start** :

```bash
# Check logs
sudo snap logs percona-postgresql.postgresql

# Check data directory permissions
sudo ls -la /var/snap/percona-postgresql/current/postgresql/
```

2. Log Locations

* PostgreSQL logs: `/var/snap/percona-postgresql/current/postgresql/log/`

## Development

### Building

```bash
# Install snapcraft
sudo snap install snapcraft --classic

# Build snap
snapcraft

# Install for testing
sudo snap install *.snap --dangerous --devmode
```

### Testing

```bash
# Run all tests
make test

# Test Docker build
make build-docker

# Test cluster setup
make compose-cluster
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Security

### Best Practices

1. **Change default passwords** :

```bash
sudo snap set percona-postgresql postgres-password=strong-password
```

2. **Enable TLS** for all connections
3. **Configure firewall** rules for required ports only
4. **Regular updates** :

```bash
sudo snap refresh percona-postgresql
```

5. **Monitor logs** for suspicious activity

### Security Features

* SSL/TLS encryption support
* MD5 password authentication
* Network access controls via pg_hba.conf
* Connection limits and rate limiting
* Audit logging capabilities

## Support

* **Documentation** : [Percona PostgreSQL Documentation](https://docs.percona.com/postgresql/)
* **Community** : [Percona Community Forum](https://forums.percona.com/)
* **Issues** : Submit issues in this repository
* **Commercial Support** : [Percona Support Services](https://www.percona.com/services/support)

## License

This project is licensed under the PostgreSQL License. See individual components for their specific licenses:

* PostgreSQL: PostgreSQL License

## Changelog

### Version 17.5

* Initial release with Percona PostgreSQL 17.5
* TLS encryption support
* Docker and snap packaging
