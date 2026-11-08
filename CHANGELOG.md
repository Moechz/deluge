# Changelog

All notable user-visible changes to the Deluge TOS application package.

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
