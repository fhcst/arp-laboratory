FROM ubuntu:26.04
LABEL org.opencontainers.image.source="https://github.com/fhcst/arp-laboratory"
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl iproute2 iputils-ping \
    && rm -rf /var/lib/apt/lists/*
COPY start.sh /usr/local/bin/lab-start
ENTRYPOINT ["/bin/sh", "/usr/local/bin/lab-start"]
