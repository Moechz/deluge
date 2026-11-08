# deluge-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Deluge](https://github.com/linuxserver/docker-deluge).

## What this is

A four-file TOS Docker application archive (`delugedocker.tar.gz`) that installs
Deluge on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `delugedocker`)
- `delugedocker.lang` — 23-language superset (TOS requires 14)
- `delugedocker.svg` — application icon (678 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/deluge:2.2.0-ls386`

## How it works

| | |
|---|---|
| Container image | `linuxserver/deluge:2.2.0-ls386` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8020/` (container port 8112) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/delugedocker/config`, `/downloads` → `/Volume1/DockerAppData/delugedocker/downloads` |
| Logs | `docker logs delugedocker` (stdout/stderr) |

`config` holds the daemon and web settings; `downloads` holds the torrent data. Copying `config` keeps the client configuration; the downloads folder is your own data.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8112.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Runs as a non-root container.** Verified on real hardware as uid 1000.
- **Two volumes.** `/config` keeps the daemon/web settings; `/downloads` receives the torrent data.
- **Health check** probes the web UI on container port 8112.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, no Docker socket, no `cap_add`.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `config/auth` | daemon/web credentials and connection settings | first start | small | never overwritten; back it up |
| `/Volume1/DockerAppData/delugedocker/config` | Deluge application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/delugedocker/downloads` | Deluge application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Architectures

The TOS store takes one package per architecture. This release provides both,
built from the same sources by `scripts/build-dual.sh`:

| Architecture | Package | Size | SHA-256 |
|---|---|---|---|
| x86_64 | `delugedocker_x86_64.tar.gz` | 4208 B | `f49035bd6ac2c4cc12951a17240febc1fa3fe88bb6f93c99c022e37bab8177f8` |
| aarch64 | `delugedocker_aarch64.tar.gz` | 4208 B | `e63da03bd4f6345fcc5e69e499dd17c628ef42198c3031b09534ff85da435db7` |

The x86_64 package was verified with the full on-device E2E; the aarch64 package
passes the official `TOSAppSelfTestingTool -c` check and the developer platform's
automated validation (no ARM host was available for a container E2E).

## Build

```bash
scripts/build.sh                  # -> out/delugedocker.tar.gz + .sha256
scripts/build.sh 2.2.0-2   # packaging iteration bump
scripts/build.sh 2.2.0-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/delugedocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v2.2.0-1`**, assets `delugedocker.tar.gz` +
   `delugedocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `delugedocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `2.2.0-1` → automated validation → review.

## License / branding

Deluge is distributed by its upstream authors under **GPL-3.0-only**. The container image is the official image from Docker Hub (`linuxserver/deluge:2.2.0-ls386`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

Only the web UI port is published. Incoming peer connections need UPnP/NAT-PMP or router port forwarding; outgoing connections still download.
`/downloads` belongs to this app only and is not shared with the Radarr/Sonarr/Lidarr packages.
No VPN is included. Use a VPN or a trusted network if your torrent traffic must be private.
The page is plain HTTP on the LAN; use a TLS reverse proxy before exposing it to the internet, and change the default password immediately.
Docker applications cannot be upgraded in place in the App Center: updating means uninstalling and reinstalling, which keeps the data folders.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
