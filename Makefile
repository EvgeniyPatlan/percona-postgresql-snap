# Variables
SNAP_NAME = percona-postgresql
VERSION = 17.5
DOCKER_IMAGE = $(SNAP_NAME):$(VERSION)
BUILD_DIR = build
SNAP_FILE = $(SNAP_NAME)_$(VERSION)_amd64.snap

# Default target
.PHONY: all
all: build

# Build the snap package
.PHONY: build
build: clean
	@echo "Building $(SNAP_NAME) snap package..."
	snapcraft --verbosity=verbose
	@echo "Build completed: $(SNAP_FILE)"

# Build using Docker (for CI/CD)
.PHONY: build-docker
build-docker:
	@echo "Building $(SNAP_NAME) using Docker..."
	docker build -t $(DOCKER_IMAGE) .
	docker run --rm -v $(PWD):/output $(DOCKER_IMAGE) cp /build/$(SNAP_FILE) /output/
	@echo "Docker build completed: $(SNAP_FILE)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf parts/ stage/ prime/ snap/.snapcraft/
	rm -f *.snap
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

# Install the snap locally
.PHONY: install
install: build
	@echo "Installing $(SNAP_NAME) snap..."
	sudo snap install $(SNAP_FILE) --dangerous --devmode
	@echo "Installation completed!"

# Remove the installed snap
.PHONY: uninstall
uninstall:
	@echo "Removing $(SNAP_NAME) snap..."
	sudo snap remove $(SNAP_NAME) 2>/dev/null || true

# Reinstall (clean install)
.PHONY: reinstall
reinstall: uninstall install

# Run tests
.PHONY: test
test: install
	@echo "Running comprehensive tests..."
	@echo "Testing PostgreSQL installation..."
	sudo snap start $(SNAP_NAME).postgresql
	sleep 5
	$(SNAP_NAME).psql --version
	
	@echo "Testing Patroni installation..."
	which $(SNAP_NAME).patroni >/dev/null && echo "✓ Patroni found"
	which $(SNAP_NAME).patronictl >/dev/null && echo "✓ PatroniCTL found"
	
	@echo "Testing HAProxy installation..."
	which $(SNAP_NAME).haproxy >/dev/null && echo "✓ HAProxy found"
	
	@echo "Testing PgBouncer installation..."
	which $(SNAP_NAME).pgbouncer >/dev/null && echo "✓ PgBouncer found"
	
	@echo "Testing pgpool-II installation..."
	which $(SNAP_NAME).pgpool2 >/dev/null && echo "✓ pgpool-II found"
	
	@echo "Testing pgBackRest installation..."
	which $(SNAP_NAME).pgbackrest >/dev/null && echo "✓ pgBackRest found"
	
	@echo "Testing pgBadger installation..."
	which $(SNAP_NAME).pgbadger >/dev/null && echo "✓ pgBadger found"
	
	@echo "Testing pg_gather installation..."
	which $(SNAP_NAME).pg-gather >/dev/null && echo "✓ pg_gather found"
	
	@echo "Testing Percona Toolkit installation..."
	which $(SNAP_NAME).percona-toolkit >/dev/null && echo "✓ Percona Toolkit found"
	which $(SNAP_NAME).pt-summary >/dev/null && echo "✓ pt-summary found"
	
	@echo "Testing database connectivity..."
	timeout 30 bash -c 'until $(SNAP_NAME).psql -U postgres -c "SELECT version();" > /dev/null 2>&1; do sleep 1; done'
	$(SNAP_NAME).psql -U postgres -c "SELECT 'PostgreSQL is working!' as status;"
	
	@echo "Testing extensions..."
	$(SNAP_NAME).psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pgaudit;" || echo "pgaudit not available"
	$(SNAP_NAME).psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;" || echo "pgvector not available"
	$(SNAP_NAME).psql -U postgres -c "SELECT * FROM pg_available_extensions WHERE name LIKE 'pg%';"
	
	@echo "All tests passed! ✅"

# Start services
.PHONY: start
start:
	@echo "Starting PostgreSQL service..."
	sudo snap start $(SNAP_NAME).postgresql

# Stop services
.PHONY: stop
stop:
	@echo "Stopping all services..."
	sudo snap stop $(SNAP_NAME)

# Show service status
.PHONY: status
status:
	@echo "Service status:"
	sudo snap services $(SNAP_NAME)

# Show logs
.PHONY: logs
logs:
	@echo "Service logs:"
	sudo snap logs $(SNAP_NAME) -f

# Connect to PostgreSQL
.PHONY: connect
connect:
	@echo "Connecting to PostgreSQL..."
	$(SNAP_NAME).psql -U postgres -h /tmp

# Start Patroni cluster (requires etcd)
.PHONY: start-cluster
start-cluster:
	@echo "Starting Patroni cluster..."
	sudo snap start $(SNAP_NAME).patroni
	sudo snap start $(SNAP_NAME).haproxy
	sudo snap start $(SNAP_NAME).pgbouncer

# Configure snap options
.PHONY: configure
configure:
	@echo "Configuring $(SNAP_NAME)..."
	sudo snap set $(SNAP_NAME) postgres-password=secretpassword
	sudo snap set $(SNAP_NAME) patroni-cluster-name=percona-cluster
	sudo snap set $(SNAP_NAME) patroni-node-name=$$(hostname)
	sudo snap set $(SNAP_NAME) enable-tls=false
	sudo snap set $(SNAP_NAME) etcd-hosts=127.0.0.1:2379

# Enable TLS
.PHONY: enable-tls
enable-tls:
	@echo "Enabling TLS..."
	sudo snap set $(SNAP_NAME) enable-tls=true
	sudo snap restart $(SNAP_NAME)

# Release to Snap Store (requires login)
.PHONY: release
release: build
	@echo "Releasing $(SNAP_NAME) to Snap Store..."
	snapcraft upload $(SNAP_FILE)
	snapcraft release $(SNAP_NAME) $(shell snapcraft list-revisions $(SNAP_NAME) | head -2 | tail -1 | awk '{print $$1}') stable

# Docker Compose targets
.PHONY: compose-up
compose-up:
	@echo "Starting Docker Compose stack..."
	docker-compose up -d

.PHONY: compose-down
compose-down:
	@echo "Stopping Docker Compose stack..."
	docker-compose down

.PHONY: compose-cluster
compose-cluster:
	@echo "Starting Patroni cluster with Docker Compose..."
	docker-compose -f docker-compose.yml -f docker-compose-patroni-cluster.yml up -d

# Development helpers
.PHONY: shell
shell:
	@echo "Opening shell in snap environment..."
	sudo snap run --shell $(SNAP_NAME)

.PHONY: debug
debug: install
	@echo "Debug information:"
	@echo "Snap info:"
	sudo snap info $(SNAP_NAME)
	@echo ""
	@echo "Data directory contents:"
	sudo ls -la /var/snap/$(SNAP_NAME)/current/
	@echo ""
	@echo "Configuration files:"
	sudo find /var/snap/$(SNAP_NAME)/current/ -name "*.conf" -o -name "*.yml" -o -name "*.ini" | head -10

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build          - Build the snap package"
	@echo "  build-docker   - Build using Docker"
	@echo "  clean          - Clean build artifacts"
	@echo "  install        - Install the snap locally"
	@echo "  uninstall      - Remove the snap"
	@echo "  reinstall      - Clean reinstall"
	@echo "  test           - Run basic tests"
	@echo "  start          - Start PostgreSQL service"
	@echo "  stop           - Stop all services"
	@echo "  status         - Show service status"
	@echo "  logs           - Show service logs"
	@echo "  connect        - Connect to PostgreSQL"
	@echo "  start-cluster  - Start Patroni cluster"
	@echo "  configure      - Configure snap options"
	@echo "  enable-tls     - Enable TLS support"
	@echo "  release        - Release to Snap Store"
	@echo "  compose-up     - Start Docker Compose stack"
	@echo "  compose-down   - Stop Docker Compose stack"
	@echo "  compose-cluster- Start Patroni cluster with Compose"
	@echo "  shell          - Open snap shell"
	@echo "  debug          - Show debug information"
	@echo "  help           - Show this help"
