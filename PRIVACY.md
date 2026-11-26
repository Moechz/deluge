# Privacy Policy — Deluge for TerraMaster TOS (`delugedocker`)

**Last updated:** 22 November 2026 (package `2.2.0-3`)
**Data controller / contact:** Moechz — moechz@163.com — <https://www.moechz.com/privacy.html>
**App:** `delugedocker`, the TerraMaster TOS 7 Docker packaging of Deluge 2.2.0

This policy describes **exactly** what the app writes, what leaves the NAS and to whom.
It was rewritten in `2.2.0-3` because the previous text described a different kind of
application (indexers and download-client integrations) and therefore did not match the
real behaviour of a BitTorrent client. See §10 for the correction list.

## 2. Short version

- The developer operates **no server** in any data path of this app: there is no telemetry,
  no analytics SDK, no crash reporting, no account and no cloud sync.
- Everything the app stores, it stores **on your NAS**, below
  `/Volume1/DockerAppData/delugedocker/`.
- The app **does** talk to the internet. That traffic is BitTorrent traffic produced by the
  torrents **you** add — the trackers listed in those torrents, the DHT, and the peers — plus
  a small, documented set of upstream checks listed in §6.
- BitTorrent has **no anonymity layer**. Your public IP address, client port and transfer
  counters are visible to the trackers, DHT nodes and peers of every torrent you add, and to
  anyone who can query the DHT for that torrent's infohash.

## 3. What is stored, and where

| Container path | Host path | Content |
|---|---|---|
| `/config` | `/Volume1/DockerAppData/delugedocker/config` | `auth` (web/daemon credentials as a salted hash), `core.conf` (preferences incl. listen ports, limits, DHT/UPnP/encryption switches), `torrents.state` + `torrents.fastresume` (torrent list and resume data), `hostlist.conf` (web UI allow-list), `plugins/` (state of plugins you enable), `deluged.log` (daemon log), `deluged.pid` |
| `/downloads` | `/Volume1/DockerAppData/delugedocker/downloads` | the downloaded payload and the torrent files/metadata, i.e. the data you asked for |

Nothing else is written outside these two folders. The container's `/tmp` is discarded with
the container.

**The developer receives none of it.** We have no endpoint, no copy and no way to read it.

## 4. Retention

- **App data:** kept until **you** delete it. There is no automatic expiry, and uninstalling
  the app keeps the folders unless you tick “delete data”.
- **Logs:** `deluged.log` grows at the level selected by `DELUGE_LOGLEVEL` (this package sets
  `error`); it is never uploaded.
- **Remote copies:** if a tracker, DHT node or peer kept your IP/port, or a tracker kept your
  announce counters, its own retention policy applies — we cannot delete data on third-party
  systems we do not control.
- **Developer website (`moechz.com`):** if you visit it, ordinary short-lived web-server logs
  (IP, user agent) are kept for operations only; they are not used for profiling and are not
  linked to the app.

## 5. Your rights and the deletion channel

| Right | How |
|---|---|
| Access / export | Copy `/Volume1/DockerAppData/delugedocker/` — it is the complete state (settings + payload + torrent metadata). |
| Correct | Change the values in the app's own web UI (`http://<NAS-IP>:8020/`). |
| Delete | Uninstall the app with “delete data”, or stop the container and remove the folder. |
| Restrict outbound traffic | Turn off DHT, peer exchange, LSD, UPnP/NAT-PMP or the release check in the web UI (see §6, “How to switch it off”). |
| Assistance / complaints | Email **moechz@163.com** with the subject “Deluge data request”; answered within 30 days. |

Because the developer holds no copy of your data, deletion is completed by deleting the
folder on your own NAS; the email channel exists for questions, for the developer website and
for the published packaging records.

## 6. What leaves the NAS (third-party API disclosure)

All traffic below is generated **by the upstream Deluge 2.2.0 client inside the container**,
not by the packaging. This table is the complete list as implemented in the version shipped by
`2.2.0-3` (verified against the code and the running container).

| # | Trigger | Endpoint | Data sent | Destination / region |
|---|---|---|---|---|
| 1 | Adding a torrent (always) | the **trackers named inside that torrent/magnet file** (HTTP/HTTPS/UDP, you supply them) | infohash, random peer id, your public IP:port, up/downloaded/left counters, announce event | the tracker operator's servers, wherever they are hosted |
| 2 | Adding a torrent (default **on**) | **DHT**: bootstrap node `dht.libtorrent.org:25401` (UDP), then other DHT nodes discovered from it | infohash, your IP:port, DHT queries/announces | public DHT swarm worldwide |
| 3 | Downloading/seeding (default **on**) | **peers** over TCP/UDP on the listen port (default random 6881–6891) | your IP:port, client name/version, piece availability, transfer counters | other BitTorrent users worldwide |
| 4 | Downloading (default **on**) | **peer exchange (PEX)** with connected peers | the peers you are connected to | other BitTorrent users worldwide |
| 5 | Same LAN (default **on**) | **LSD / local peer discovery**: multicast `239.192.x.x:6771`, SSDP `239.255.255.250:1900` | infohash, your LAN IP | your own LAN only — no internet |
| 6 | Container start, then every **3 days** (default **on**) | `https://ftp.osuosl.org/pub/deluge/version-2.0` — “check for new release” | source IP + HTTP user agent only; the file is the current version string | OSU Open Source Lab, Oregon, US |
| 7 | Only if you enable “send anonymous stats” (default **off**) | `http://deluge-torrent.org/stats_get.php?processor=<arch>&python=<ver>&deluge=<ver>` at most weekly | CPU architecture, Python version, Deluge version, source IP | deluge-torrent.org, US/EU |
| 8 | Only if you press “Test active port” in the UI | `https://deluge-torrent.org/test_port.php?port=<listen port>` | your listening port (and therefore your IP) | deluge-torrent.org, US/EU |
| 9 | Port mapping (default **on**) | **UPnP-IGD / NAT-PMP** (`:1900`, `:5351`) toward the container's gateway. With the bridge network used by this package the gateway is Docker's bridge, so the request does not reach your router — the daemon still tries | requested port mapping for the listen port | Docker's bridge gateway (no internet) |
| 10 | Only if you enable the **Blocklist** plugin | the blocklist URL **you** configure | source IP + user agent | the URL you chose |
| 11 | Installing / updating the app | `registry-1.docker.io` (Docker Hub) or your configured mirror | anonymous image pull of `linuxserver/deluge:2.2.0-ls388` | Docker Hub, US, or your mirror |
| 12 | Any of the above that uses a hostname | your configured **DNS resolver** | the hostname being resolved | your DNS provider |

No other endpoint is contacted. In particular: no analytics, no crash reporting, no advertising
identifier, no update check against the developer's servers, and **no data sent to Moechz**.

### How to switch it off

- **DHT / PEX / LSD / UPnP / NAT-PMP:** web UI → *Preferences → Network* → untick the
  corresponding boxes (older UI: *Network → Network Extras*).
- **Release check:** *Preferences → Other* → untick “Check for new releases”
  (`new_release_check`, default on).
- **Anonymous stats:** *Preferences → Other* → leave “Send anonymous stats” unticked
  (`send_info`, default off in Deluge 2.2.0).
- **Proxy / VPN:** *Preferences → Network → Proxy* supports SOCKS5/HTTP proxies; for full
  traffic separation run the container behind a VPN or on a network whose exit you trust.
  The packaging itself does not ship a VPN.
- **Whole app:** stop the container — no traffic leaves the NAS while it is stopped.

## 7. Children

The app is a self-hosted utility, not directed at children, and it does not knowingly process
children's data.

## 8. Security measures

- The container runs as **uid/gid 1000** with **all Linux capabilities dropped**
  (`cap_drop: [ALL]`, `CapEff=0000000000000000` measured in the running container) and
  `no-new-privileges`; it has no `privileged`, no host network, no Docker socket and no
  `cap_add`.
- Only the web port is published (`8020 → 8112`). The BitTorrent listen port stays inside the
  container network: the daemon's UPnP/NAT-PMP request goes to Docker's bridge gateway, so
  incoming peers need a listen port forwarded manually on the router.
- The image tag **and digest** are pinned (`linuxserver/deluge:2.2.0-ls388@sha256:52314116…`)
  and the package is rebuilt when upstream ships a security fix; no `:latest`.
- The web UI ships the upstream default password `deluge`; **change it on first login**. The
  password is stored in `config/auth` as a salted hash.
- The UI is plain HTTP on the LAN. Put a TLS reverse proxy in front of it before exposing it
  to the internet, and restrict who can reach port 8020.
- Data files stay inside the app data folder and are owned by uid 1000. The entrypoint
  wrapper runs with `umask 027`, keeps `/config` owner-only (0700/0600, `config/auth` is 0600)
  and `/downloads` group-readable (0750), so credentials are not readable by other users.

## 9. Scope

This policy covers the packaging `delugedocker` and the unmodified upstream image it runs.
Third-party trackers, DHT nodes, peers, Docker Hub, OSU OSL and deluge-torrent.org are
independent controllers with their own policies; we cannot make statements on their behalf.

## 10. Changes in `2.2.0-3` (why the previous text was wrong)

The previous policy (and the store description) claimed the app “contacts only the services
you configure”, that the only outbound check was “an optional update check against GitHub”,
and described “indexers” and a “download client” — those are integration points of a
media-manager (Sonarr/Radarr style) app, not of a BitTorrent client. The corrected facts:

1. Deluge contacts the **trackers, DHT and peers of your torrents** by design; this is the
   application's core function and is now disclosed in §6 rows 1–4, including the resulting
   **public-IP exposure**.
2. The release check goes to **`ftp.osuosl.org`**, not GitHub, and is **on by default**
   (§6 row 6).
3. A second, opt-in upstream check exists — **anonymous stats to `deluge-torrent.org`**,
   default **off** (§6 row 7) — plus a user-triggered **port test** (§6 row 8).
4. Local-network discovery and UPnP/NAT-PMP belong in the disclosure too (§6 rows 5 and 9).

Material future changes are published in this file and reflected in the “Last updated” date.

## 11. Contact

Moechz — **moechz@163.com** — <https://www.moechz.com/privacy.html>
