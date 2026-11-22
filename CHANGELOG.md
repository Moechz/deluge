# Changelog

All notable user-visible changes to the Deluge TOS application package.

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
