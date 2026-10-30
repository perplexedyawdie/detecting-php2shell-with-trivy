# Ubuntu 24.04 with php8.3-cli from the archive as it is today (the fixed .13).
FROM ubuntu:24.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends php8.3-cli \
 && rm -rf /var/lib/apt/lists/*
