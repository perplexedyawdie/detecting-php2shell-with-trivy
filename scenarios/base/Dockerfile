# Ubuntu 24.04 with the vulnerable php8.3 build (8.3.6-0ubuntu0.24.04.12),
# pulled straight from Launchpad. The fix is 8.3.6-0ubuntu0.24.04.13.
FROM ubuntu:24.04

ARG TARGETARCH
ARG LP=https://launchpad.net/ubuntu/+archive/primary/+files
ARG V=8.3.6-0ubuntu0.24.04.12

ADD ${LP}/php8.3-cli_${V}_${TARGETARCH}.deb      /tmp/debs/php8.3-cli.deb
ADD ${LP}/php8.3-common_${V}_${TARGETARCH}.deb   /tmp/debs/php8.3-common.deb
ADD ${LP}/php8.3-opcache_${V}_${TARGETARCH}.deb  /tmp/debs/php8.3-opcache.deb
ADD ${LP}/php8.3-readline_${V}_${TARGETARCH}.deb /tmp/debs/php8.3-readline.deb

WORKDIR /tmp/debs
RUN apt-get update \
 && apt-get install -y --no-install-recommends ./*.deb \
 && rm -rf /tmp/debs /var/lib/apt/lists/*
WORKDIR /
