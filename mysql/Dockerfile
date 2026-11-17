# MySQL 8.4 LTS: Fleet's database. Fleet supports MySQL 8.0.44+, 8.4 and 9.5; 9.6 is incompatible,
# so this stays on 8.4 LTS, pinned by version and digest. Data lives on the /var/lib/mysql volume.
FROM mysql:8.4.13@sha256:a81d043930e51745522bd5c430961cf8286f0a23f0a9a2a6e0108f7ea71b0902

COPY --chmod=755 railway-start.sh /usr/local/bin/railway-start.sh
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
