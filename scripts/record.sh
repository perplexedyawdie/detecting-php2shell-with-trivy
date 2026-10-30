#!/usr/bin/env bash
# Types and runs one condition's demo (holds, then broken).
#
#   asciinema rec --cols 100 --rows 28 -i 1.5 --overwrite -c "scripts/record.sh c1" recordings/c1.cast
#   npx svg-term-cli --in recordings/c1.cast --out recordings/c1.svg --window --padding 18
set -u
cd "$(dirname "$0")/.."

trivy() { docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.76.1 "$@"; }

PROMPT=$'\e[1;35mphp2shell\e[0m \e[1;36m❯\e[0m '
HITS="grep -c '\"VulnerabilityID\": \"CVE-2026-109618\"'"

type_out() {
  local s=$1 i
  for ((i = 0; i < ${#s}; i++)); do printf '%s' "${s:i:1}"; sleep 0.02; done
}

demo() {
  local line
  clear
  while IFS= read -r -u 3 line; do
    [[ -z $line ]] && continue
    line=${line//'$HITS'/$HITS}
    printf '%s' "$PROMPT"
    if [[ $line == \#* ]]; then
      printf '\e[2;3m'; type_out "$line"; printf '\e[0m\n'; sleep 0.5
      continue
    fi
    type_out "$line"; printf '\n'
    eval "$line"
    sleep 1.5
  done
  printf '%s' "$PROMPT"; sleep 2; printf '\n'
}

c1() { demo 3<<'EOF'
# holds: php8.3 installed from .deb, so dpkg knows about it
docker compose exec c1-holds php -v | head -1
docker compose exec c1-holds dpkg -l 'php8.3*' | awk '/^ii/ {print $2, $3}'
trivy image -q --list-all-pkgs -f json php2shell:c1-holds | jq -r '.Results[].Packages[].Name' | grep php
# broken: same PHP built from source, dpkg never hears about it
docker compose exec c1-broken-source php -v | head -1
docker compose exec c1-broken-source dpkg -l 'php8.3*'
trivy image -q --list-all-pkgs -f json php2shell:c1-broken-source | jq -r '.Results[].Packages[].Name' | grep php
# broken: installed from .deb, then /var/lib/dpkg deleted
docker compose exec c1-broken-no-db php -v | head -1
docker compose exec c1-broken-no-db dpkg -l 'php8.3*'
trivy image php2shell:c1-broken-no-db 2>&1 | grep -o 'No OS package is detected.*'
EOF
}

c2() { demo 3<<'EOF'
# holds: os-release says Ubuntu 24.04
docker compose exec c2-holds grep -E '^(ID|VERSION_ID)=' /etc/os-release
trivy image -q -f json php2shell:c2-holds | jq -c .Metadata.OS
trivy image -q -f json php2shell:c2-holds | $HITS
# broken: os-release says fakeos 1.0, lsb-release and debian_version removed
docker compose exec c2-broken grep -E '^(ID|VERSION_ID)=' /etc/os-release
docker compose exec c2-broken ls /etc/lsb-release /etc/debian_version
trivy image -q -f json php2shell:c2-broken | jq -c .Metadata.OS
trivy image -q -f json php2shell:c2-broken | $HITS
EOF
}

c3() { demo 3<<'EOF'
# holds: php8.3-* maintained by Ubuntu
docker compose exec c3-holds dpkg-query -W -f='${Package}: ${Maintainer}\n' 'php8.3-*' | grep @
trivy image --debug php2shell:c3-holds 2>&1 | grep -o 'Skipping third-party packages.*'
trivy image -q -f json php2shell:c3-holds | $HITS
# broken (simulated): same packages, Maintainer rewritten to Docker's
docker compose exec c3-broken dpkg-query -W -f='${Package}: ${Maintainer}\n' 'php8.3-*' | grep @
trivy image --debug php2shell:c3-broken 2>&1 | grep -o 'Skipping third-party packages.*'
trivy image -q -f json php2shell:c3-broken | $HITS
EOF
}

c4() { demo 3<<'EOF'
# holds: noble (24.04), and the advisory has a noble entry
docker compose exec c4-holds grep VERSION_CODENAME /etc/os-release
docker compose exec c4-holds dpkg-query -W php8.3-cli
curl -s https://raw.githubusercontent.com/aquasecurity/vuln-list/main/ubuntu/2026/CVE-2026-109618.json | jq -c '.Patches."php8.3".noble'
trivy image -q -f json php2shell:c4-holds | $HITS
# broken: oracular (24.10), php8.3 installed, but no oracular entry
docker compose exec c4-broken grep VERSION_CODENAME /etc/os-release
docker compose exec c4-broken dpkg-query -W php8.3-cli
curl -s https://raw.githubusercontent.com/aquasecurity/vuln-list/main/ubuntu/2026/CVE-2026-109618.json | jq -c '.Patches."php8.3".oracular'
trivy image php2shell:c4-broken 2>&1 | grep -o 'This OS version is no longer supported.*'
trivy image -q -f json php2shell:c4-broken | $HITS
EOF
}

c5() { demo 3<<'EOF'
# holds: the .12 build from Launchpad
docker compose exec c5-holds dpkg-query -W -f='${Version}\n' php8.3-cli
docker compose exec c5-holds sh -c 'dpkg --compare-versions "$(dpkg-query -W -f="\${Version}" php8.3-cli)" lt 8.3.6-0ubuntu0.24.04.13 && echo below fix || echo at/after fix'
trivy image -q -f json php2shell:c5-holds | $HITS
# broken: whatever apt installs today (.13)
docker compose exec c5-broken dpkg-query -W -f='${Version}\n' php8.3-cli
docker compose exec c5-broken sh -c 'dpkg --compare-versions "$(dpkg-query -W -f="\${Version}" php8.3-cli)" lt 8.3.6-0ubuntu0.24.04.13 && echo below fix || echo at/after fix'
trivy image -q -f json php2shell:c5-broken | $HITS
EOF
}

c6() { demo 3<<'EOF'
# holds: today's DB has the advisory
docker run --rm php2shell:stale-db --cache-dir /fresh version | grep UpdatedAt
docker run --rm --entrypoint dbkey php2shell:stale-db get /fresh/db/trivy.db 'ubuntu 24.04' php8.3 CVE-2026-109618
trivy image -q -f json php2shell:c6-holds | $HITS
# broken (simulated): a DB from before 21 Oct, same image, --skip-db-update
docker run --rm php2shell:stale-db version | grep UpdatedAt
docker run --rm --entrypoint dbkey php2shell:stale-db get /root/.cache/trivy/db/trivy.db 'ubuntu 24.04' php8.3 CVE-2026-109618
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock php2shell:stale-db image -q -f json --skip-db-update php2shell:c6-holds | $HITS
EOF
}

c7() { demo 3<<'EOF'
# holds: default scan, every severity
trivy image -q -f json php2shell:c7-holds | jq -r '.Results[].Vulnerabilities[]? | select(.VulnerabilityID=="CVE-2026-109618") | .Severity' | sort -u
trivy image -q -f json php2shell:c7-holds | $HITS
# broken: same image, scan settings filter it out
trivy image -q -f json --severity LOW,MEDIUM php2shell:c7-holds | $HITS
docker run --rm -e TRIVY_SEVERITY=LOW,MEDIUM -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.76.1 image -q -f json php2shell:c7-holds | $HITS
cat scenarios/c7-filters/.trivyignore
docker run --rm -v "$PWD/scenarios/c7-filters/.trivyignore:/.trivyignore" -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.76.1 image -q -f json --ignorefile /.trivyignore php2shell:c7-holds | $HITS
EOF
}

case ${1:-} in
  c[1-7]) "$1" ;;
  *) echo "usage: $0 c1..c7" >&2; exit 2 ;;
esac
