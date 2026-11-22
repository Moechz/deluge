# NOTICE — licences, third-party components and attributions

This package (`delugedocker`, a TerraMaster TOS 7 Docker application) is an independent
packaging by **Moechz** of the upstream **Deluge** BitTorrent client, run unmodified from the
LinuxServer.io image. It contains **no upstream source code**; it pulls the image at install
time.

## 1. Upstream application — Deluge

| | |
|---|---|
| Application | Deluge 2.2.0 |
| Project / source | <https://github.com/deluge-torrent/deluge> |
| Website | <https://deluge-torrent.org> |
| Licence | **GNU GPL version 3 or later**, with the OpenSSL linking exception |
| Licence expression used here | `GPL-3.0-or-later` + OpenSSL exception |
| Copyright | © the Deluge team and contributors |

### The licence, verified — and corrected in this release

Earlier releases of this package declared `GPL-3.0-only` in `tosapp.json` and in the store
metadata. **That was wrong** and is corrected in `2.2.0-3` (review finding **C2**). What the
shipped image actually reports:

- `deluge-2.2.0.dist-info/METADATA`: `License: GPLv3+`,
  classifier `License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)`;
- `deluge-2.2.0.dist-info/LICENSE` starts with: *“Deluge is licensed under the GNU General
  Public License version 3 with the addition of the following special exception: … the
  copyright holders give permission to link the code of portions of this program with the
  OpenSSL library.”*

So the correct statement is **GPL-3.0-or-later, with the OpenSSL linking exception** — not
`-only`, and not “GPL-3.0” without the exception.

> **Why the old metadata said `-only`:** the image's own label
> `org.opencontainers.image.licenses` reads `GPL-3.0-only`. That label belongs to
> LinuxServer.io's packaging of the image, not to Deluge's source, and it contradicts the
> Deluge `METADATA`/`LICENSE` shipped inside the same image. We follow the application's
> actual licence (`GPL-3.0-or-later` + OpenSSL exception) and keep LinuxServer.io's label
> recorded here so the discrepancy is traceable rather than silently copied.

### GPL compliance

- No GPL-covered code is redistributed in this package: the archive contains only the
  packaging files (§4). The GPL programme itself is shipped **inside the container image**, by
  its image maintainer.
- Corresponding source for the image is published by LinuxServer.io:
  <https://github.com/linuxserver/docker-deluge> (build scripts) and
  <https://github.com/deluge-torrent/deluge> (Deluge itself); release artefacts are at
  <https://ftp.osuosl.org/pub/deluge/>.
- The licence text of the GPL-3.0 is the one inside the image
  (`/lsiopy/lib/python3.12/site-packages/deluge-2.2.0.dist-info/LICENSE`); we do not
  relicense or modify Deluge.

## 2. Container image — `linuxserver/deluge:2.2.0-ls387`

| | |
|---|---|
| Registry | Docker Hub, `linuxserver/deluge:2.2.0-ls387` (used unmodified, tag pinned) |
| Maintainer | LinuxServer.io — <https://github.com/linuxserver/docker-deluge> (GPL-3.0) |
| Image label licence | `GPL-3.0-only` (LinuxServer.io's own label; see the note in §1) |
| OCI image index | `sha256:e2a537991884a514b64d7adf857e39b5e9239a1c76e52114e52bf10707dde772` |
| `linux/amd64` manifest | `sha256:bd74af6a1e88f7ee6061dba04a048f426d613ec7d04b8b75222ccb193df2b9c9` |
| `linux/arm64` manifest | `sha256:2a63fea7dae7f5d005937fb5b1bd13a1db4ebd85216c9b6db586602c9854b832` |
| Platforms | x86_64 (amd64) and aarch64 (arm64) — both manifests verified while preparing this release |
| Previous image | `linuxserver/deluge:2.2.0-ls386` (shipped in `2.2.0-2`) — superseded by ls387 for the CVE remediation (finding T1) |

The image is **pulled from Docker Hub at install time and is not redistributed** in this
package. The digests above are content-addressed identifiers, recorded so that a rebuilt
release can be compared byte for byte.

### Components inside the image

The image bundles, among others, **libtorrent-rasterbar 2.0.13** (BSD-3-Clause), the Alpine
base with musl libc, s6-overlay (ISC), Python 3.12 and Deluge's Python dependencies. Their
licence texts and package metadata ship inside the image
(`/usr/share/licenses`, `/lsiopy/lib/python3.12/site-packages/*.dist-info/`); they are not
redistributed as separate files by this package. Nothing here changes those licences.

## 3. Trademarks and marks

- **“Deluge”** and the Deluge droplet logo belong to the Deluge project. They are used here
  only to identify the software this package installs (nominative use). This package is **not
  affiliated with, sponsored or endorsed by** the Deluge project.
- **“LinuxServer.io”** and the LinuxServer.io branding belong to LinuxServer.io; the image is
  used unmodified and this package is not an official LinuxServer.io release.
- **“TerraMaster”** and **“TOS”** are trademarks of TerraMaster. They are used descriptively
  to state the platform this package targets.
- The application icon `src/delugedocker.svg` is a vector reproduction of the Deluge droplet
  mark, used solely to identify the application in the App Center. It is not claimed as an
  original work of the packager; the mark remains the property of its owner.

## 4. This packaging

The files authored for this package — `docker-compose.yml`, `config.ini`,
`delugedocker.lang`, `delugedocker.svg` (the drawing, not the underlying mark), the build and
verification scripts (`scripts/`, `tools/`, `test/`) and this documentation — are released
under the **MIT licence** (see `LICENSE`). They contain no upstream Deluge code, so the GPL
does not extend to them; conversely, the MIT licence does not apply to Deluge or to the image.

## 5. No warranty

The packaging is provided “as is”, without warranty of any kind. Deluge and the container
image carry their own warranties (or disclaimers) from their respective authors.

## 6. Contact

Moechz — **moechz@163.com** — <https://www.moechz.com/> · privacy: [PRIVACY.md](PRIVACY.md)
