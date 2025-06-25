FROM ubuntu:22.04

# Install snapd and dependencies
RUN apt-get update && \
    apt-get install -y snapd squashfs-tools && \
    systemctl enable snapd

# Install snapcraft
RUN snap install snapcraft --classic

# Set up environment
ENV SNAPCRAFT_ENABLE_EXPERIMENTAL_EXTENSIONS=1
ENV SNAPCRAFT_BUILD_ENVIRONMENT=host

# Create working directory
WORKDIR /build

# Copy project files
COPY . /build/

# Build the snap
RUN snapcraft

# Entry point
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5432 5000 5001 6432 7000 8008

ENTRYPOINT ["/entrypoint.sh"]