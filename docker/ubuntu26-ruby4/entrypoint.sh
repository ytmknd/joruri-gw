#!/usr/bin/env bash
set -euo pipefail

cd /var/share/jorurigw

mkdir -p \
  .bundle \
  config \
  log \
  public/assets \
  tmp/cache \
  tmp/pids \
  tmp/sockets \
  upload \
  vendor/bundle

# Copy docker phase config files if target is absent or empty
for source in docker/phase5/config/*.yml; do
  target="config/$(basename "${source}")"
  if [[ -f "${source}" && ! -s "${target}" ]]; then
    cp "${source}" "${target}"
  fi
done

# Copy Gemfile.lock from phase config if not present in the working tree
if [[ -f "docker/phase5/Gemfile.lock" && ! -f "Gemfile.lock" ]]; then
  cp "docker/phase5/Gemfile.lock" "Gemfile.lock"
fi

ensure_bundle() {
  git config --global url."https://github.com/".insteadOf git://github.com/

  local bundle_version="${BUNDLER_VERSION:-2.5.23}"
  if ! BUNDLE_FROZEN=true bundle _"${bundle_version}"_ check > /dev/null 2>&1; then
    BUNDLE_FROZEN=true bundle _"${bundle_version}"_ install --path vendor/bundle
  fi
}

if [[ "$(id -u)" = "0" ]]; then
  if [[ "${CHOWN_SOURCE_TREE:-1}" = "1" ]]; then
    find . \
      \( -path './.git' -o -path './config/*.yml' \) -prune -o \
      -exec chown -h joruri:joruri {} +
  else
    chown -R joruri:joruri \
      .bundle \
      log \
      public/assets \
      tmp \
      upload \
      vendor/bundle
  fi
  ensure_bundle
  chown -R joruri:joruri \
    .bundle \
    log \
    public/assets \
    tmp \
    upload \
    vendor/bundle
  # runuser is stable under Podman/QEMU; gosu is kept as the Docker fallback.
  if command -v runuser > /dev/null 2>&1; then
    exec runuser -u joruri -- "$0" "$@"
  else
    exec gosu joruri "$0" "$@"
  fi
fi

if [[ "${1:-}" = "bundle" && "${2:-}" = "exec" && "${3:-}" = "rails" && "${4:-}" = "server" ]]; then
  rm -f tmp/pids/server.pid
fi

ensure_bundle

exec "$@"
