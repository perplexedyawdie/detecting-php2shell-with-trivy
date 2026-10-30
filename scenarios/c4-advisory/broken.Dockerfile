# Ubuntu 24.10 (oracular, EOL 2025-07-09) with php8.3-cli from old-releases.
FROM ubuntu:24.10
RUN sed -Ei 's#https?://(archive|security|ports)\.ubuntu\.com/ubuntu(-ports)?#http://old-releases.ubuntu.com/ubuntu#g' \
      /etc/apt/sources.list /etc/apt/sources.list.d/* \
 && apt-get update \
 && apt-get install -y --no-install-recommends php8.3-cli \
 && rm -rf /var/lib/apt/lists/*
