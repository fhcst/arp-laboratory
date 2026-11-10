FROM ubuntu:26.04
LABEL org.opencontainers.image.source="https://github.com/fhcst/arp-laboratory"
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl dbus dbus-x11 fonts-dejavu-core iproute2 iputils-ping \
    openssh-server python3 python3-venv python3-scapy sudo supervisor tcpdump \
    xauth xfce4 xfce4-terminal xorgxrdp xrdp xserver-xorg-core \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash student \
    && adduser xrdp ssl-cert \
    && printf 'student ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/lab-student \
    && chmod 0440 /etc/sudoers.d/lab-student \
    && printf '%s\n' 'PermitRootLogin no' 'PasswordAuthentication yes' 'AllowUsers student' \
        'DisableForwarding yes' > /etc/ssh/sshd_config.d/10-lab.conf \
    && rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub

RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get -o Acquire::Retries=3 -o Acquire::https::Timeout=30 update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gpg \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL --retry 3 https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
        | gpg --batch --dearmor -o /etc/apt/keyrings/vscodium.gpg \
    && curl -fsSL --retry 3 https://packages.mozilla.org/apt/repo-signing-key.gpg \
        -o /etc/apt/keyrings/mozilla.asc \
    && gpg --batch --show-keys --with-colons /etc/apt/keyrings/mozilla.asc \
        | grep -q '^fpr:::::::::35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3:' \
    && printf '%s\n' 'Types: deb' 'URIs: https://download.vscodium.com/debs' \
        'Suites: vscodium' 'Components: main' 'Architectures: amd64 arm64' \
        'Signed-By: /etc/apt/keyrings/vscodium.gpg' > /etc/apt/sources.list.d/vscodium.sources \
    && printf '%s\n' 'Types: deb' 'URIs: https://packages.mozilla.org/apt' \
        'Suites: mozilla' 'Components: main' \
        'Signed-By: /etc/apt/keyrings/mozilla.asc' > /etc/apt/sources.list.d/mozilla.sources \
    && printf '%s\n' 'Package: firefox' 'Pin: origin packages.mozilla.org' 'Pin-Priority: 1000' \
        > /etc/apt/preferences.d/mozilla-firefox \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends codium firefox \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        fonts-noto-cjk novnc tigervnc-standalone-server tigervnc-tools websockify xfonts-base \
    && rm -rf /var/lib/apt/lists/*

# Electron's launcher sees the WSL kernel used by Docker Desktop.
ENV DONT_PROMPT_WSL_INSTALL=1

# Docker's default restrictions block Electron's namespace sandbox.
RUN test -x /usr/bin/codium \
    && printf '%s\n' '#!/bin/sh' 'exec /usr/bin/codium --no-sandbox "$@"' > /usr/local/bin/code \
    && chmod 0755 /usr/local/bin/code \
    && sed -i 's|^Exec=/usr/share/codium/codium|& --no-sandbox|' \
        /usr/share/applications/com.visualstudio.CodeOSS*.desktop


COPY start.sh /usr/local/bin/lab-start
COPY supervisord.conf /etc/lab-supervisord.conf
COPY --chown=student:student xsession.sh /home/student/.xsession
RUN chmod 0755 /home/student/.xsession
ENTRYPOINT ["/bin/sh", "/usr/local/bin/lab-start"]
