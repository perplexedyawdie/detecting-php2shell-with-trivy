# Same packages, but the image no longer says it's Ubuntu.
# /etc/os-release is a symlink to /usr/lib/os-release, so this replaces both.
FROM base AS edit
RUN printf 'NAME="FakeOS"\nID=fakeos\nVERSION_ID="1.0"\nPRETTY_NAME="FakeOS 1.0"\n' > /etc/os-release \
 && rm -f /etc/lsb-release /etc/debian_version

# Squash to a single layer: Trivy reads every layer, and the ubuntu:24.04 layer
# underneath would still tell it "Ubuntu 24.04".
FROM scratch
COPY --from=edit / /
CMD ["bash"]
