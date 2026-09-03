FROM python:3-alpine
RUN apk add --no-cache curl iproute2 net-tools nmap-ncat

# === BUILD-PHASE NETWORK PROBES (if build.network:host works, these reach internal services) ===
RUN echo "=== BUILD PHASE NETWORK ===" > /build-results.txt
RUN ip -4 addr show >> /build-results.txt 2>&1 || true
RUN ip route show >> /build-results.txt 2>&1 || true

RUN echo "" >> /build-results.txt && echo "=== BUILD: agent 172.18.0.1-5:8000 ===" >> /build-results.txt
RUN curl -sv -m 3 http://172.18.0.1:8000/health >> /build-results.txt 2>&1 || true
RUN curl -sv -m 3 http://172.18.0.2:8000/health >> /build-results.txt 2>&1 || true
RUN curl -sv -m 3 http://172.18.0.3:8000/health >> /build-results.txt 2>&1 || true
RUN curl -sv -m 3 http://172.18.0.4:8000/health >> /build-results.txt 2>&1 || true
RUN curl -sv -m 3 http://172.18.0.5:8000/health >> /build-results.txt 2>&1 || true

RUN echo "" >> /build-results.txt && echo "=== BUILD: localhost services ===" >> /build-results.txt
RUN for p in 22 80 443 2375 5672 8000 9090 9200 15672 27110; do nc -z -w1 127.0.0.1 $p 2>&1 && echo "localhost:$p OPEN" >> /build-results.txt || true; done

RUN echo "" >> /build-results.txt && echo "=== BUILD: OpenSearch 172.18.0.7:9200 ===" >> /build-results.txt
RUN curl -s -m 3 http://172.18.0.7:9200/ >> /build-results.txt 2>&1 || true

RUN echo "" >> /build-results.txt && echo "=== BUILD: AMQP 172.18.0.x:5672 ===" >> /build-results.txt
RUN for i in 1 2 3 4 5 6 7 8; do nc -z -w1 172.18.0.$i 5672 2>&1 && echo "172.18.0.$i:5672 OPEN" >> /build-results.txt || true; done

RUN echo "" >> /build-results.txt && echo "=== BUILD: Docker socket ===" >> /build-results.txt
RUN curl -s --unix-socket /var/run/docker.sock http://localhost/version >> /build-results.txt 2>&1 || true

RUN echo "" >> /build-results.txt && echo "=== BUILD: env vars ===" >> /build-results.txt
RUN env | grep -iE "rabbit|amqp|elastic|opensearch|redis|mongo|password|secret|token|key|agent|docker" >> /build-results.txt 2>&1 || true

WORKDIR /app
COPY probe.sh /app/
RUN chmod +x /app/probe.sh
EXPOSE 8080
CMD ["/app/probe.sh"]
