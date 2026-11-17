#!/bin/sh
# Start Fleet on Railway: keep all local state on the /data volume, wait for MySQL,
# run the database migrations (`fleet prepare db`), then serve as the `fleet` user.
set -eu

: "${FLEET_MYSQL_ADDRESS:?FLEET_MYSQL_ADDRESS is required}"
: "${FLEET_REDIS_ADDRESS:?FLEET_REDIS_ADDRESS is required}"
: "${FLEET_SERVER_PRIVATE_KEY:?FLEET_SERVER_PRIVATE_KEY is required (at least 32 characters)}"

DATA="${FLEET_DATA_DIR:-/data}"

# Railway terminates TLS at its edge and sends plain HTTP to PORT.
export FLEET_SERVER_ADDRESS="${FLEET_SERVER_ADDRESS:-0.0.0.0:${PORT:-8080}}"
export FLEET_SERVER_TLS="${FLEET_SERVER_TLS:-false}"
export FLEET_LOGGING_JSON="${FLEET_LOGGING_JSON:-true}"

# Everything Fleet writes to local disk goes to the volume, so it survives redeploys.
export FLEET_SOFTWARE_INSTALLER_STORE_DIR="${FLEET_SOFTWARE_INSTALLER_STORE_DIR:-$DATA/installers}"
export FLEET_VULNERABILITIES_DATABASES_PATH="${FLEET_VULNERABILITIES_DATABASES_PATH:-$DATA/vulndb}"
export FLEET_FILESYSTEM_STATUS_LOG_FILE="${FLEET_FILESYSTEM_STATUS_LOG_FILE:-$DATA/logs/osquery_status.log}"
export FLEET_FILESYSTEM_RESULT_LOG_FILE="${FLEET_FILESYSTEM_RESULT_LOG_FILE:-$DATA/logs/osquery_result.log}"
export FLEET_FILESYSTEM_AUDIT_LOG_FILE="${FLEET_FILESYSTEM_AUDIT_LOG_FILE:-$DATA/logs/audit.log}"
# Rotate and compress those logs so they can't fill the volume.
export FLEET_FILESYSTEM_ENABLE_LOG_ROTATION="${FLEET_FILESYSTEM_ENABLE_LOG_ROTATION:-true}"
export FLEET_FILESYSTEM_ENABLE_LOG_COMPRESSION="${FLEET_FILESYSTEM_ENABLE_LOG_COMPRESSION:-true}"
export FLEET_FILESYSTEM_MAX_SIZE="${FLEET_FILESYSTEM_MAX_SIZE:-100}"
export FLEET_FILESYSTEM_MAX_BACKUPS="${FLEET_FILESYSTEM_MAX_BACKUPS:-3}"

mkdir -p "$DATA/installers" "$DATA/vulndb" "$DATA/logs"
find "$DATA" ! -user fleet -exec chown fleet:fleet {} + 2>/dev/null || true

# Railway starts all services at once, so MySQL may still be initialising.
# `fleet prepare db` creates or migrates the schema and is safe to run on every start.
tries=0
until su -s /bin/sh fleet -c '/usr/bin/fleet prepare db --no-prompt'; do
  tries=$((tries + 1))
  if [ "$tries" -ge 40 ]; then
    echo "railway-start: database not ready after $tries attempts, giving up" >&2
    exit 1
  fi
  echo "railway-start: database not ready yet (attempt $tries), retrying in 5s" >&2
  sleep 5
done

# busybox su keeps the environment; `exec` makes Fleet PID 1 so it gets Railway's stop signal.
exec su -s /bin/sh fleet -c 'exec /usr/bin/fleet serve'
