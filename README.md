# deluge-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Deluge](https://github.com/deluge-torrent/deluge) 2.2.0, run from the
> unmodified [LinuxServer.io image](https://github.com/linuxserver/docker-deluge).

Current packaging version: **`2.2.0-4`** (remediated per App Listing Review, see
[§9](#9-review-remediation)).

## 1. What this is

A four-file TOS Docker application archive that installs Deluge on TOS 7 through the App
Center:

| File | Role |
|---|---|
| `config.ini` | TOS application metadata (`application_type: docker`, id `delugedocker`, `path` → port 8020, `help` → <https://moechz.github.io/deluge/>, the rendered help page) |
| `delugedocker.lang` | 23-language metadata superset (TOS requires 14) |
| `delugedocker.svg` | application icon (744 bytes, 4 SVG elements, 512×512 viewBox) |
| `docker-compose.yml` | one service running `linuxserver/deluge:2.2.0-ls388` (digest-pinned), non-root, hardened, `tmpfs` `/run`, port `8020:8112` |

The archive contains no binaries and no upstream source code: the container image is pulled
from Docker Hub at install time. The archive ships the entrypoint wrapper inline in the compose
file (see `src/entrypoint.sh`).

## 2. Repository layout

```text
.
├── README.md                     this file
├── PRIVACY.md                    privacy policy + third-party endpoint disclosure
├── NOTICE.md                     licences, image digests, trademarks, attributions
├── CHANGELOG.md                  per-version changes, mapped to review codes
├── LICENSE                       MIT licence of *this packaging* (not of Deluge)
├── tosapp.json                   packaging spec read by scripts/ and tools/
├── TOSAppSelfTestingTool         official TOS package checker (binary, run with -c)
├── docs/
│   └── index.md                  rendered help page published by GitHub Pages (help URL)
├── src/                          the four files that go into the archive (+ wrapper source)
│   ├── config.ini
│   ├── delugedocker.lang
│   ├── delugedocker.svg
│   ├── docker-compose.yml
│   └── entrypoint.sh             umask/permission wrapper, embedded into the compose file
├── scripts/
│   ├── build.sh                  build one architecture → out/<appid>.tar.gz
│   └── build-dual.sh             build x86_64 + aarch64, verify both, write .sha256
├── tools/
│   └── verify.py                 review-standards self-check (hard build gate)
└── test/
    ├── smoke.sh                  functional smoke test (Web UI + login + add/query task)
    └── install-and-verify.sh     on-device E2E (needs root; not needed for review)
```

`build/`, `out/` and `test/compose-resolved/` are generated and git-ignored; the released
artefacts live in GitHub Releases, not in the tree.

## 3. How it works

| | |
|---|---|
| Container image | `linuxserver/deluge:2.2.0-ls388` (Docker Hub, unmodified, tag **and digest** pinned) |
| Image index digest | `sha256:52314116ba684ae5cdcbd380758be2a5f7cc866b4235f44ba7af8ff7c35c42b7` (amd64 `7dc70065…`, arm64 `749f3cd3…`) |
| Open | `http://<NAS-IP>:8020/` → container port 8112 |
| Runs as | uid/gid `1000:1000`, `cap_drop: [ALL]`, `no-new-privileges`, `CapEff=0` |
| `/run` | tmpfs owned by uid/gid 1000 (s6-overlay aborts with exit code 100 if it cannot own `/run`) |
| Entrypoint | `src/entrypoint.sh` → `umask 027`, owner-only `/config`, then `exec /init` |
| Persistent data | `/config` → `/Volume1/DockerAppData/delugedocker/config`<br>`/downloads` → `/Volume1/DockerAppData/delugedocker/downloads` |
| Health check | `curl -s -o /dev/null http://127.0.0.1:8112/` every 30 s (curl ships in the image) |
| Logs | `docker logs delugedocker` (level from `DELUGE_LOGLEVEL=error`) |
| Default password | `deluge` — change it on first login |

## 4. Ports

| Direction | Port | Notes |
|---|---|---|
| Web UI (published) | host `8020` → container `8112/tcp` | the only published port; unchanged since `2.2.0-1` |
| BitTorrent listen (not published) | container `6881–6891` (random) | inbound peers need a listen port forwarded on your router. The container is on a bridge network, so the daemon's UPnP/NAT-PMP request reaches Docker's gateway, not the router. Outgoing connections work regardless |
| Daemon RPC (not published) | container `58846/tcp` | used only inside the container |

The host port stays inside TOS' recommended `8000–19999` range and avoids the reserved ports
(22/80/443/445/3306/5050/5432/6379/8181/8443).

## 5. Data, backup and uninstall

| Path | Content |
|---|---|
| `config/auth` | web/daemon credentials (salted hash) |
| `config/core.conf` | preferences: listen ports, limits, DHT/UPnP/encryption switches, proxy |
| `config/state/torrents.state`, `config/state/torrents.fastresume` | torrent list, queue and resume data |
| `config/hostlist.conf`, `config/web.conf` | web UI allow-list and local daemon entry / web UI settings |
| `config/plugins/` | state of enabled plugins |
| `config/deluged.log` | daemon log |
| `downloads/` | the torrent payload (default save path) |

- **Backup:** copy `/Volume1/DockerAppData/delugedocker/`. `config` alone is enough to keep the
  client setup; `downloads` is your own data.
- **Uninstall:** uninstalling from the App Center keeps both folders. Tick “delete data” (or
  stop the container and remove the folder) to delete everything.
- **Upgrade:** Docker apps cannot be upgraded in place — uninstall and reinstall; the data
  folders survive.

## 6. Privacy

The developer receives **nothing**: no telemetry, no analytics, no crash reporting, no
account. All data stays in `/Volume1/DockerAppData/delugedocker/`.

The app *does* talk to the internet, because that is what a BitTorrent client does: the
trackers named in your torrents, the DHT, and the peers — plus two upstream checks. Your
public IP is visible to those third parties for every torrent you add. Full details, the
complete endpoint table and the opt-out switches are in **[PRIVACY.md](PRIVACY.md)**.

## 7. Third-party endpoints (summary)

| # | Endpoint | Sent | When |
|---|---|---|---|
| 1 | trackers inside your torrent/magnet | infohash, peer id, IP:port, counters | every announce |
| 2 | DHT — bootstrap `dht.libtorrent.org:25401`, then other nodes | infohash, IP:port | while a torrent is active (default on) |
| 3 | peers / PEX (TCP+UDP) | IP:port, client version, piece map | while transferring (default on) |
| 4 | LSD (LAN multicast `239.192.x.x:6771`, SSDP `:1900`) | infohash, LAN IP | on the LAN only |
| 5 | `https://ftp.osuosl.org/pub/deluge/version-2.0` | IP + user agent | at start, then every 3 days (default **on**) |
| 6 | `http://deluge-torrent.org/stats_get.php?…` | arch, python/deluge version | weekly, only if “send anonymous stats” is enabled (default **off**) |
| 7 | `https://deluge-torrent.org/test_port.php?port=…` | listen port | only when you press “Test active port” |
| 8 | `registry-1.docker.io` (or your mirror) | anonymous pull | install/update |

The developer operates none of these. See [PRIVACY.md](PRIVACY.md) §6 for data, region and
how to switch each one off.

## 8. Notices and licences

| Component | Licence |
|---|---|
| Deluge 2.2.0 (inside the image) | **GPL-3.0-or-later with the OpenSSL linking exception** — verified from the image's `deluge-2.2.0.dist-info/METADATA` (`GPLv3+`) and `LICENSE` |
| Image `linuxserver/deluge:2.2.0-ls388` | LinuxServer.io build, GPL-3.0; the image label says `GPL-3.0-only` (see NOTICE §1) |
| This packaging (compose, metadata, translations, docs, scripts) | **MIT** (see `LICENSE`) — no upstream code is included |

“Deluge”, “LinuxServer.io”, “TerraMaster” and “TOS” are trademarks of their respective
owners and are used descriptively only. This is an independent community package by Moechz; it
is not affiliated with or endorsed by the Deluge project, LinuxServer.io or TerraMaster.
Full attributions, image digests and the licence-correction note: **[NOTICE.md](NOTICE.md)**.

## 9. Review remediation

### 9.1 `2.2.0-4` (review of `2.2.0-3`)

Review of `2.2.0-3` (x86_64 + aarch64) listed **C9, T1** in the summary and, in the review
tables, the blocking rows **P2, F2, S11** (x86_64) and **P2, F2, F7** (aarch64). This round
looked at what `2.2.0-3` actually delivered instead of re-stating the old conclusions:

| Finding | What `2.2.0-3` did | Fix in `2.2.0-4` |
|---|---|---|
| **F2** service fails to start, container exits `100` | Added `cap_drop: [ALL]` but never mounted its own `/run`; s6-overlay's preinit exits `100` when `/run` is owned by a different uid and it cannot chown it (reproduced locally with the same compose file and image: `exit=100`) | `tmpfs: /run` owned by uid/gid 1000 with `exec`, so the start-up no longer depends on the install-time `/run` |
| **C9** description inconsistent | Rewrote the wording, but kept **65 ASCII semicolons** in `app.lang`; the store parses `.lang` as INI, so every `descript` was cut at the first `;` | All values rewritten without ASCII semicolons; `tools/verify.py` now fails the build if a lang value contains one; the UPnP claim was dropped (bridge networking cannot open a router port) |
| **P2** help link | Pointed at `blob/main/PRIVACY.md` (raw source on a code host) | `help` → <https://moechz.github.io/deluge/>, rendered from `docs/`, public, no sign-in |
| **S11** file permissions | Non-root, but `/config`/`/downloads` kept the platform's default modes | `umask 027`, `/config` 0700 (files 0600), `/downloads` 0750 via `src/entrypoint.sh` |
| **F7** web interface | Never started on aarch64 because of F2 | Same F2 fix; verified with `test/smoke.sh`: page loads, wrong password rejected, login, daemon connect, add/list/remove a torrent |
| **T1** CVE | Bumped to `ls387` (2026-11-09) | LinuxServer.io has since published **`2.2.0-ls388`** (2026-11-24), now pinned by index digest `sha256:52314116…` |

### 9.2 `2.2.0-3` (review of `2.2.0-2`)

Review of `2.2.0-2` (x86_64 + aarch64) raised the union of `C10 C2 C6 C8 T1` plus the
blocking rows printed in the aarch64 notice. What changed:

| Finding | Fix in `2.2.0-3` |
|---|---|
| **C6** data collection inconsistent with the declaration | `PRIVACY.md` rewritten around the *actual* traffic of a BitTorrent client; the previous text described indexers/download clients and a GitHub update check that the app never performs. Release check (`ftp.osuosl.org`), opt-in anonymous stats (`deluge-torrent.org`), port test, DHT/PEX/LSD/UPnP are now disclosed. Store description, `important`, `release_note` and all 23 language strings rewritten to match. |
| **C8** third-party APIs not disclosed | Endpoint table (endpoint → data → destination/region) in `PRIVACY.md` §6 and README §7, including the **outbound tracker/DHT/peer traffic with public-IP exposure** caused by the torrents the user adds. |
| **C2** intellectual property | Licence corrected to **GPL-3.0-or-later + OpenSSL exception** (was `GPL-3.0-only`, copied from an image label); `NOTICE.md` rewritten with source links, image index + per-arch digests, trademark attribution, packaging licence and a GPL source-availability section. |
| **C10** repository/directory compliance | README rewritten with Repository layout / How it works / Ports / Data & uninstall / Privacy / Notices / Build / Architectures / Remediation; `help` in `config.ini` and `tosapp.json` now points at `blob/main/PRIVACY.md`. |
| **T1** high/critical CVE | Image bumped `2.2.0-ls386` → **`2.2.0-ls387`** (newest LinuxServer.io build, 2026-11-09). Upstream Deluge 2.2.0 is still the latest release, so no newer application version exists. |
| **V1** runs as root (aarch64 notice) | Package already pinned `user: "1000:1000"`; this release additionally drops **all** capabilities and sets `no-new-privileges`. Measured in the running container: `id` → uid 1000, `CapEff=0000000000000000`, no root process in `ps`. |
| **F1 / V10** install failed, architecture mismatch (aarch64 notice) | Could not be reproduced from the published `2.2.0-2` artefact (that aarch64 archive already declared `platform=aarch64` and the image is a multi-arch OCI index). Mitigated anyway: the aarch64 archive is rebuilt and re-verified (`config.ini platform == aarch64`), the image was bumped to ls387, and submission now uses the per-arch release asset `delugedocker_aarch64.tar.gz` rather than any generic fallback. |
| **V5 / V7 / V12 / V4** rows in the aarch64 notice | Checked and not applicable / verified: `delugedocker` is already a unique app id on the platform (no duplicate exists), the submitted SHA-256 is verified against the platform `file_hash` after submission, and the archive contains no executable, no obfuscated content and no third-party code (four text/metadata files only). |

## 10. Build and verification

```bash
# both architectures -> out/delugedocker_{x86_64,aarch64}.tar.gz + .sha256
scripts/build-dual.sh 2.2.0-4

# single architecture
scripts/build.sh 2.2.0-4 x86_64
```

`scripts/build.sh` stages the four files, substitutes `@@VERSION@@`/`@@PLATFORM@@`, strips
CRLF/BOM/AppleDouble, runs `tools/verify.py` as a hard gate (archive layout, JSON validity,
required fields, 14+ languages, version consistency, Docker-Hub-only image, fixed tag,
reserved/recommended ports, non-root user, per-service healthcheck/TZ/restart, data paths below
the application data root, no `/Volume*` wildcard, comment-free sequence blocks, `x-app-meta`
position, no literal secrets, icon limits), then packs with GNU tar (uid/gid 0, mtime 0) and
gzip (no timestamp) so the archive is reproducible.

Official check (both archives must report a pass):

```bash
./TOSAppSelfTestingTool -c out/delugedocker_x86_64.tar.gz
./TOSAppSelfTestingTool -c out/delugedocker_aarch64.tar.gz
```

Isolated runtime check (temporary ports, `/tmp` data, never the production folder):

```bash
python3 ../stage.py . --timeout 300     # isolated compose up + HTTP + non-root assertions
bash test/smoke.sh http://127.0.0.1:<staged-port>   # functional: login + add/query task
python3 ../smoke.py . --timeout 300     # generic availability gate, runs test/smoke.sh
```

## 11. Architectures and checksums (`2.2.0-4`)

| Architecture | Package | Size | SHA-256 |
|---|---|---|---|
| x86_64 | `delugedocker_x86_64.tar.gz` | 6553 B | `c091d7ccae30be43d13fbf6ebc19b239943863635efa59c1a7993dfb13e89c07` |
| aarch64 | `delugedocker_aarch64.tar.gz` | 6554 B | `64cdf594a7d7e32d1215e99dde5c32dcc905549dd9203c291b78dbb2421b80fa` |

Both archives were built from the same sources by `scripts/build-dual.sh` and pass the official
`TOSAppSelfTestingTool -c` check. x86_64 was additionally started in an isolated staging
project (container running/healthy, HTTP 200, uid 1000, `/config` 0700, `config/auth` 0600,
`test/smoke.sh` 8/8 checks OK). **No ARM host was available**, so the aarch64
archive is verified statically (declared `platform=aarch64`, image provides
`linux/arm64` manifest `sha256:749f3cd3…`) rather than by running it.

## 12. Security notes

- Non-root, all capabilities dropped, `no-new-privileges`; no `privileged`, no host network,
  no Docker socket, no `cap_add`, no `group_add`.
- One published port (8020). The web UI is plain HTTP and ships with the upstream password
  `deluge` — change it, and put a TLS reverse proxy in front before exposing it.
- BitTorrent traffic is **not** anonymised. Use a VPN or a trusted network if that matters to
  you; the package intentionally does not bundle one.
- The image tag is pinned; this package is rebuilt when upstream ships security fixes.

## 13. Store submission

1. Public GitHub repo (this tree) with tag `v2.2.0-4`.
2. Release assets: `delugedocker_x86_64.tar.gz`, `delugedocker_aarch64.tar.gz` and both
   `.sha256` files.
3. Developer platform → Deluge → new version `2.2.0-4` for **x86_64 and aarch64**; submission
   remarks: “Rectified per review comments”.
4. After submission, compare the platform `file_hash` with the local `sha256sum` (V7/S12).

## 14. Support

- Issues and questions: <https://github.com/Moechz/deluge/issues>
- Email: moechz@163.com
- Privacy: [PRIVACY.md](PRIVACY.md) · Licences/attributions: [NOTICE.md](NOTICE.md) ·
  Changes: [CHANGELOG.md](CHANGELOG.md)
