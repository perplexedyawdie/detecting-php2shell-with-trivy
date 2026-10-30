# SIMULATED stale Trivy DB: a stand-in for a DB built before the Ubuntu advisory
# for CVE-2026-109618 was published (2026-10-21T14:17Z).
#
# trivy-db is only published as rolling tags (1, 2, latest), so no genuinely old
# DB can be pulled. Instead this downloads today's DB and:
#   /fresh/db               - kept exactly as downloaded
#   /root/.cache/trivy/db   - same DB with the key CVE-2026-109618 deleted from
#                             bucket "ubuntu 24.04" > "php8.3", dates set to 2026-10-20
# Scan with --skip-db-update so Trivy uses the stale copy instead of downloading.
#
# Behind a TLS-inspecting proxy? Add: --secret id=ca,src=/path/to/ca-bundle.crt

FROM golang:1.25 AS tool
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=secret,id=ca,target=/etc/ssl/certs/ca-certificates.crt,required=false \
    go mod download
COPY dbkey.go ./
RUN CGO_ENABLED=0 go build -o /dbkey .

FROM aquasec/trivy:0.76.1
COPY --from=tool /dbkey /usr/local/bin/dbkey
RUN --mount=type=secret,id=ca,target=/etc/ssl/certs/ca-certificates.crt,required=false \
    trivy image --download-db-only --no-progress --cache-dir /fresh
RUN mkdir -p /root/.cache/trivy \
 && cp -r /fresh/db /root/.cache/trivy/db \
 && dbkey del /root/.cache/trivy/db/trivy.db 'ubuntu 24.04' php8.3 CVE-2026-109618 \
 && sed -i -E 's/"(UpdatedAt|DownloadedAt)":"[^"]*"/"\1":"2026-10-20T07:00:00Z"/g; s/"NextUpdate":"[^"]*"/"NextUpdate":"2026-10-21T07:00:00Z"/' \
      /root/.cache/trivy/db/metadata.json
