# Simulation: the php8.3-* packages are the real Ubuntu ones, but their
# Maintainer field is rewritten to look like they came from a third-party repo
# (Docker's). That field is what Trivy's dpkg analyzer checks.
FROM base
RUN perl -00 -pi -e 's/^Maintainer: .*$/Maintainer: Docker <support\@docker.com>/m if /^Package: php8\.3-/m' \
      /var/lib/dpkg/status
