# Fleet (open-source device management): the public web UI, API and osquery/fleetd endpoint.
# Official image, pinned by version and digest. Bump both together and add a CHANGELOG entry.
FROM fleetdm/fleet:v4.95.0@sha256:14fe5700b07b448131f87d27480e37005e0943f4a9af8fa3cab2b2fe4988459d

# The image runs as the unprivileged `fleet` user, but Railway mounts volumes as root.
# The start script fixes the volume's ownership as root, then drops to `fleet` with busybox `su`.
USER root
COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
