#!/bin/bash
# Start MySQL for Fleet on Railway.
set -euo pipefail
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
export MYSQL_DATABASE="${MYSQL_DATABASE:-fleet}"
export MYSQL_USER="${MYSQL_USER:-fleet}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

# A fresh Railway volume contains lost+found, which MySQL's first-run init refuses.
rm -rf /var/lib/mysql/lost+found

# Railway's own MySQL flags (no native AIO, no binary log, no performance schema to save memory),
# listening on IPv4 and IPv6 for Railway's private network,
# plus the large packet size Fleet needs to store MDM bootstrap packages.
exec docker-entrypoint.sh mysqld \
  --innodb-use-native-aio=0 \
  --disable-log-bin \
  --performance-schema=0 \
  --bind-address=* \
  --max_allowed_packet=536870912 \
  "$@"
