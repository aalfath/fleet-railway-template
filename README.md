[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/fleet?utm_medium=integration&utm_source=button&utm_campaign=fleet)

# Fleet on Railway

This repo packages [Fleet](https://github.com/fleetdm/fleet) **v4.95.0** as a Railway template. Fleet is open-source device management: it enrolls macOS, Windows, Linux, ChromeOS, iOS and Android hosts, shows live inventory and software, runs osquery queries and policies, finds vulnerable software, and (with your own Apple or Windows MDM setup) manages profiles and OS updates.

Every app service builds from a folder of this repo. Each folder has a Dockerfile that pins the official upstream image by version **and** digest, plus a small start script.

## What it deploys

| Service | Source | Image | Role | Volume |
| --- | --- | --- | --- | --- |
| **Fleet** (public) | `fleet/` | `fleetdm/fleet:v4.95.0` | Web UI, REST API, osquery and fleetd endpoint, cron jobs | `/data` (software installers, vulnerability databases, rotated osquery logs) |
| **MySQL** | `mysql/` | `mysql:8.4.13` (LTS) | Fleet's main database | `/var/lib/mysql` |
| **Redis** | Railway's Redis | Railway's `redis` image | Live query results, caches | Railway's Redis volume |

Only Fleet has a public domain. MySQL and Redis are reachable only over Railway's private network. Fleet supports MySQL 8.0.44 or later, 8.4 and 9.5, and MySQL 9.6 is incompatible, so the template stays on 8.4 LTS.

On every start, the Fleet service waits for MySQL, runs `fleet prepare db` (creates or migrates the schema), then starts `fleet serve` as the unprivileged `fleet` user. The health check is `/healthz`.

## Variables

You don't have to fill in anything to deploy. Railway generates every password and secret, and services find each other through reference variables.

| Service | Variable | Default | Notes |
| --- | --- | --- | --- |
| Fleet | `FLEET_SERVER_PRIVATE_KEY` | generated (48 chars) | Encrypts secrets Fleet stores in MySQL (MDM certificates, API keys). Don't change it after the first start |
| Fleet | `FLEET_MYSQL_*` | references | Wiring to the MySQL service |
| Fleet | `FLEET_REDIS_ADDRESS`, `FLEET_REDIS_PASSWORD` | references | Wiring to the Redis service |
| Fleet | `PORT` | `8080` | Fleet listens here; the public domain points to it |
| MySQL | `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD` | generated | |
| MySQL | `MYSQL_DATABASE`, `MYSQL_USER` | `fleet`, `fleet` | |

Fixed settings are in `fleet/railway-start.sh`: plain HTTP behind Railway's TLS edge, JSON logs, and all local state under `/data` with log rotation. Any `FLEET_*` variable you set on the Fleet service overrides them. See [Fleet's configuration reference](https://fleetdm.com/docs/configuration/fleet-server-configuration).

## After deploy

1. Open the Fleet service's public URL. Fleet's setup page asks for your name, email, password and organization name, and creates the first admin. Until you finish it, anyone with the URL could do so, so do it right away.
2. Fleet sets its server URL to the address you used during setup. If you later add a custom domain, change it under **Settings > Organization settings > Fleet web address**.
3. Enroll hosts: **Hosts > Add hosts** builds a fleetd installer or shows the osquery flags for your server URL and enroll secret.
4. Optional, set as variables on the Fleet service: SMTP (or configure it in **Settings**), `FLEET_LICENSE_KEY` for Fleet Premium, `FLEET_S3_SOFTWARE_INSTALLERS_*` to store installers in S3 instead of the volume, and Apple or Windows MDM (see [Fleet's MDM setup guide](https://fleetdm.com/docs/using-fleet/mdm-setup)).

## Resources

Fleet uses about 150 to 300 MB of memory when idle and more while it processes vulnerabilities (it downloads NVD and OVAL data into `/data/vulndb` every hour). MySQL uses about 400 MB. Give the Fleet volume enough room for the software installers you upload.

## Not included

- **TLS inside the container:** Railway's edge terminates TLS, so Fleet runs with `FLEET_SERVER_TLS=false`.
- **Several Fleet replicas:** local installer storage works for one Fleet instance only. To scale out, move installers to S3 first.
- **Fleet's vulnerability dashboard** and other optional tools from the Fleet repo.

## Updates

Railway sends deployers an "update available" notice when this repo's `main` branch changes. Each change bumps a pinned version and digest and adds an entry to [`CHANGELOG.md`](CHANGELOG.md), with breaking changes listed first. Read it before you apply an update. Fleet migrates its database on start, and it can't be downgraded after a migration, so back up the MySQL volume before you apply an update. Read [Fleet's release notes](https://github.com/fleetdm/fleet/releases) for changes that need action.

## Local test

Build both folders with `docker build`, and run them on one Docker network with a `redis` container and the variables above (use the container names as hosts, for example `FLEET_MYSQL_ADDRESS=mysql:3306`). The template was tested this way and on Railway before publishing.

## License

The template files are MIT. Fleet is MIT, except the `ee/` directory (Fleet Premium features, which need a license key). MySQL is GPL-2.0 and Redis is under its own license.
