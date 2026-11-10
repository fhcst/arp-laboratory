FROM ubuntu:26.04
LABEL org.opencontainers.image.source="https://github.com/fhcst/arp-laboratory"
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2 libapache2-mod-php curl iproute2 \
    && rm -rf /var/lib/apt/lists/* /var/www/html/index.html \
    && printf 'ServerName arp-lab\n' > /etc/apache2/conf-available/lab.conf \
    && a2enconf lab \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log
COPY web/ /var/www/html/
COPY start.sh /usr/local/bin/lab-start
ENTRYPOINT ["/bin/sh", "/usr/local/bin/lab-start"]
