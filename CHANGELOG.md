# Changelog

Breaking changes are listed first in each entry. Read the entry before you apply an update from Railway.

## 2026-11-17: Fleet v4.95.0 (first release)

- Fleet `fleetdm/fleet:v4.95.0@sha256:14fe5700b07b448131f87d27480e37005e0943f4a9af8fa3cab2b2fe4988459d`
- MySQL `mysql:8.4.13@sha256:a81d043930e51745522bd5c430961cf8286f0a23f0a9a2a6e0108f7ea71b0902` (8.4 LTS)
- Redis: Railway's Redis service.
- The Fleet service waits for MySQL, runs `fleet prepare db` on every start, then serves as the `fleet` user. Software installers, vulnerability databases and rotated osquery logs live on the `/data` volume.
