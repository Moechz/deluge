# Changelog

All notable user-visible changes to the Deluge TOS application package.

## 2.2.0-4 — 2026-11-26

Remediation of the App Listing Review on **`2.2.0-3`** (x86_64 and aarch64 both on hold).
Review codes: **C9, T1** in the mail summary; the review tables additionally listed **P2, F2,
S11** (x86_64) and **P2, F2, F7** (aarch64). All of them are blocking rows, so all were fixed.
Submission remarks: “Rectified per review comments”.

### Why `2.2.0-3` still failed (root cause, not a wording retry)

- **F2 — the container really did not start.** The only place in this image that exits with
  **code 100** is s6-overlay's preinit, and it does so when `/run` is not owned by the uid the
  container runs as:
  `preinit: fatal: /run belongs to uid X instead of Y, has insecure and/or unworkable
  permissions, and we're lacking the privileges to fix it`. With `cap_drop: [ALL]` (added in
  `2.2.0-3`) the process cannot chown `/run` either, so preinit aborts, the container exits
  `100`, and `restart: unless-stopped` loops it — exactly what the review reports. Reproduced
  locally with the same compose file, same image and a uid other than the owner of `/run`
  (`exit=100`, s6 preinit message above). `2.2.0-3` never mounted its own `/run`, so the start-up
  depended on how the install environment creates it. `2.2.0-4` pre-mounts it as a tmpfs owned
  by uid/gid 1000 (`tmpfs: /run:rw,exec,nosuid,nodev,mode=0755,uid=1000,gid=1000`), the same
  pattern already shipped in the published `qbittorrentdocker` package.
- **C9 — the description was cut by the store parser, not merely inaccurate.** `app.lang`
  contained **65 ASCII semicolons**, including inside every `descript` value
  (`… as a non-root container; settings and downloads stay …`). The platform parses `.lang`
  as INI, so `;` starts a comment: the description shown in the listing ended at the first
  semicolon and the rest of the sentence was dropped. `2.2.0-4` rewrites every value without
  ASCII semicolons (full-width “；” or a rewritten sentence) and `tools/verify.py` now **fails
  the build** if a lang value contains one. The text itself was also re-checked against the
  delivered behaviour and one claim was dropped: in bridge networking the daemon's UPnP request
  goes to Docker's gateway, so it cannot open a router port — the description no longer implies
  that incoming peers work through UPnP.
- **P2 — help URL was a source-browsing page.** `help` pointed at
  `https://github.com/Moechz/deluge/blob/main/PRIVACY.md`, i.e. raw source on a code host.
  It now points at the rendered help page **<https://moechz.github.io/deluge/>** (GitHub Pages
  built from `docs/`, public, no sign-in). `config.ini` and `tosapp.json` carry the same URL.
- **S11 — file permissions.** The entrypoint wrapper now sets `umask 027`, tightens `/config` to
  0700/0600 (`config/auth` was already 0600) and keeps `/downloads` at 0750, so nothing in the
  data folder is group- or world-writable. The container still runs as uid/gid 1000 with
  `cap_drop: [ALL]` and `no-new-privileges`.
- **F7 — web interface.** A consequence of F2 on aarch64 (the container never reached a running
  state). Verified this round with a real functional probe, not just a port check:
  `test/smoke.sh` loads the Web UI, proves a wrong password is rejected, logs in, connects the
  Web UI to the daemon and adds + lists + removes a torrent.
- **T1 — a newer base build exists this time.** LinuxServer.io published
  **`2.2.0-ls388`** (build date 2026-11-24) after the `ls387` used in `2.2.0-3`
  (2026-11-09). The image is bumped to ls388, **pinned by index digest**
  `sha256:52314116ba684ae5cdcbd380758be2a5f7cc866b4235f44ba7af8ff7c35c42b7`
  (amd64 `7dc70065…`, arm64 `749f3cd3…`).

### Changed

- `src/docker-compose.yml`: image → `linuxserver/deluge:2.2.0-ls388@sha256:52314116…`;
  `tmpfs: /run` (uid/gid 1000, exec) to fix the exit-100 start-up; entrypoint wrapper;
  port **8020:8112 unchanged** (RUNBOOK §12).
- `src/entrypoint.sh` (new): `umask 027`, recreates `/run/deluged-temp`, owner-only `/config`,
  group-readable `/downloads`, then `exec /init`.
- `src/delugedocker.lang`, `tosapp.json`: description/important/release_note rewritten without
  ASCII semicolons, aligned with the delivered features; `help` → the rendered help page;
  `translations` zh-cn/zh-hk updated; `design_notes`/`limitations`/`runtime_files` corrected
  (`config/state/…`, tmpfs `/run`, bridge-networking peer limitation).
- `tools/verify.py`: new hard gate — an ASCII semicolon in any lang value fails the build (C9).
- `test/smoke.sh` (new): Web UI + login + add/query/remove task, exit code non-zero on failure.
- `docs/index.md` (new): the rendered help page served by GitHub Pages.
- `README.md`, `NOTICE.md`, `PRIVACY.md`, `CHANGELOG.md`: image/digest refresh, remediation
  table for this round, smoke-test and permission notes.

### Verified

- `scripts/build-dual.sh 2.2.0-4` → `verify OK` for both architectures; official
  `TOSAppSelfTestingTool -c` passes on both archives.
- Isolated staging: container running/healthy, HTTP 200, `user=1000:1000`,
  `/config` 0700, `config/auth` 0600.
- `test/smoke.sh` against the staged instance: 8/8 checks OK (page, wrong-password rejection,
  login, daemon connect, version, add task, list task, cleanup).
- Checksums are recorded in README §11 and in the `out/*.sha256` files of the release.

## 2.2.0-3 — 2026-11-22

Remediation of the App Listing Review on `2.2.0-2` (x86_64 and aarch64 were both on hold).
Review codes: **C10, C2, C6, C8, T1** (union), plus the blocking rows in the aarch64 notice.
Submission remarks: “Rectified per review comments”.

### Changed (compliance)
- **C6 — data collection now matches the declaration.** `PRIVACY.md` was rewritten from
  scratch. The previous text described *indexers* and a *download client* (integration points
  of a media manager) and an “optional update check against GitHub” — none of which Deluge
  does. The policy now documents what the client really sends: tracker announces, DHT, peer
  exchange, LSD, UPnP/NAT-PMP, the release check against `ftp.osuosl.org` (default **on**,
  every 3 days), opt-in anonymous stats to `deluge-torrent.org` (default **off**) and the
  user-triggered `test_port.php` call. Store description, `important`, `release_note` and all
  23 language strings were rewritten to match.
- **C8 — third-party API disclosure.** `PRIVACY.md` §6 and README §7 now carry an
  endpoint → data → destination/region table, explicitly stating that the outbound
  tracker/DHT/peer traffic exists because of the torrents the user adds and that it **exposes
  the user's public IP**; the opt-out switches are listed per entry.
- **C2 — licence corrected.** The package declared `GPL-3.0-only` (copied from the image's
  `org.opencontainers.image.licenses` label). The Deluge shipped inside the image reports
  `License: GPLv3+` and its `LICENSE` carries the OpenSSL linking exception, so the metadata is
  now **`GPL-3.0-or-later`** and `NOTICE.md` was rewritten: upstream source links, image index
  digest `sha256:e2a53799…` plus per-arch manifests, trademark attribution, packaging licence
  (MIT) and GPL source-availability notes.
- **C10 — repository/directory compliance.** README rewritten with Repository layout, How it
  works, Ports, Data/backup/uninstall, Privacy, Third-party endpoints, Notices, Build,
  Architectures/checksums, Security and the remediation table. `help` in `config.ini` and
  `tosapp.json` now points at `blob/main/PRIVACY.md`; the repository is public.
- `tosapp.json`: `design_notes`, `limitations`, `data_notes` and `runtime_files` rewritten to
  describe the real runtime files and the real network exposure.

### Changed (security / installation)
- **T1 — CVE remediation:** image `linuxserver/deluge:2.2.0-ls386` → **`2.2.0-ls387`**
  (newest LinuxServer.io build, 2026-11-09; index
  `sha256:e2a537991884a514b64d7adf857e39b5e9239a1c76e52114e52bf10707dde772`). Upstream
  Deluge 2.2.0 is still the newest release, so no newer application version exists.
- **V1 — root:** the service already ran as `1000:1000`; it now also uses
  `cap_drop: [ALL]` and `security_opt: [no-new-privileges:true]`. Verified in the running
  container: uid 1000, `CapEff=0000000000000000`, no root process.
- **F1 / V10 — aarch64 install / architecture:** not reproducible from the published
  `2.2.0-2` aarch64 artefact (it already declared `platform=aarch64`, and the image is a
  multi-arch OCI index). The aarch64 archive was rebuilt and re-verified, and submission uses
  the per-architecture release asset `delugedocker_aarch64.tar.gz`.
- Port unchanged: **8020 → 8112** (`config.ini` path, `x-app-meta` and compose still agree).

### Verified
- `scripts/build-dual.sh 2.2.0-3` → `verify OK` for both architectures; official
  `TOSAppSelfTestingTool -c` reports a pass for both archives.
- Isolated staging: container healthy, HTTP 200 on the mapped port, `user=1000:1000`.
- Checksums: x86_64 `e54da649189c1f9b01d4e631c68e9f9a0c78192e4285c33a73d572f40457e0e6`
  (5408 B), aarch64 `37d2a0164da056a1f05c704dd78b67daa3f4c281fb3732d8dacd22bafd2ea0ce`
  (5404 B).

## 2.2.0-1 — 2026-11-08

### Added
- First release. Deluge (`linuxserver/deluge:2.2.0-ls386`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8020 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/delugedocker/`.

### Architectures
- Dual-architecture release: `delugedocker_x86_64.tar.gz` (4208 B, `f49035bd6ac2c4cc12951a17240febc1fa3fe88bb6f93c99c022e37bab8177f8`) and
  `delugedocker_aarch64.tar.gz` (4208 B, `e63da03bd4f6345fcc5e69e499dd17c628ef42198c3031b09534ff85da435db7`), built by `scripts/build-dual.sh`.
  x86_64 has the full on-device E2E; aarch64 passes the official check and the
  platform validation (no ARM host available for a container E2E).
