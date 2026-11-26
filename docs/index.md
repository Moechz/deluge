---
title: Deluge for TerraMaster TOS
---

# Deluge for TerraMaster TOS 7

Deluge 2.2.0 is a BitTorrent client. This package installs it as a Docker application in the
TerraMaster App Center, using the unmodified LinuxServer.io image
`linuxserver/deluge:2.2.0-ls388` from Docker Hub.

This page is the end-user help document for the package. It is also the target of the `help`
field in the application metadata.

## Install

1. App Center → search for **Deluge** → **Install**. DockerEngine is required.
2. Data folders are created below `/Volume1/DockerAppData/delugedocker/`:
   `config` keeps the client settings, `downloads` is where the torrent payload is written.
3. Start the application. The first start prepares the daemon and the Web UI.

## Open and sign in

- Open `http://<NAS-IP>:8020/` (or use the App Center **Open** button).
- The Web UI ships with the upstream first-run password **`deluge`**. Change it right away:
  *Preferences → Interface → Password*.
- If the Web UI shows the *Connection Manager* instead of the torrent list, select the local
  daemon (`127.0.0.1:58846`) and press **Connect**. The Web UI then talks to the daemon that
  runs inside the same container.

## Add a task

- **Add Torrent → File**: upload a `.torrent` file.
- **Add Torrent → URL**: paste a magnet link or the URL of a `.torrent` file.
- Set the download location to `/downloads` (the default), or a subfolder below it, so the data
  ends up in `/Volume1/DockerAppData/delugedocker/downloads`.
- The list shows progress, peers, seeds and speed. Right-click a task for pause, queue,
  recheck, move storage and remove/delete.

## Ports

| Port | Purpose |
|---|---|
| `8020/tcp` on the NAS → `8112/tcp` in the container | Deluge Web UI (the only published port) |

Incoming peer connections are **not** available out of the box: the container is on a Docker
bridge network, so the daemon's UPnP/NAT-PMP request reaches Docker's gateway instead of your
router. If you need inbound peers (better ratios, faster swarms), forward one TCP/UDP port on
your router to the NAS and set it as the listen port in *Preferences → Network → Incoming Ports*.
Outgoing connections, trackers and DHT work without any forwarding.

## Privacy

The developer receives nothing: no telemetry, no analytics, no account. The BitTorrent traffic
you start does expose your public IP to the trackers, DHT nodes and peers of the torrents you
add, exactly like any other BitTorrent client. The full data-flow and third-party endpoint table
is in [PRIVACY.md](https://github.com/Moechz/deluge/blob/main/PRIVACY.md).

## Data, backup and uninstall

- Back up `/Volume1/DockerAppData/delugedocker/`. Copying `config` keeps the settings and the
  torrent list; `downloads` is your own data.
- Uninstalling from the App Center keeps both folders. To delete everything, tick the
  “delete data” option during uninstall, or remove the folder after stopping the container.
- Docker applications cannot be upgraded in place: uninstall and reinstall to update, the data
  folders survive.

## Security notes

- The container runs as uid/gid 1000 with every Linux capability dropped and
  `no-new-privileges`. It never runs as root, has no Docker socket and no host network.
- `/config` is owner-only, so the password hash is not readable by other NAS users.
- The Web UI is plain HTTP. Put a TLS reverse proxy in front of it before exposing port 8020 to
  the internet, and change the default password.

## Troubleshooting

- **The page does not open**: check the container state in the App Center. The health check
  calls `http://127.0.0.1:8112/` inside the container; `docker logs delugedocker` shows the
  daemon log.
- **“Connection lost” in the Web UI**: the daemon is still starting. Wait a few seconds and
  press **Connect** again in the Connection Manager.
- **Nothing downloads**: check that the tracker in the torrent is reachable and that the
  torrent is not paused. `/downloads` must stay writable by uid 1000.

## Support and notices

- Issues: <https://github.com/Moechz/deluge/issues>
- Privacy policy: <https://github.com/Moechz/deluge/blob/main/PRIVACY.md>
- Licences, image digests and attributions:
  <https://github.com/Moechz/deluge/blob/main/NOTICE.md>
- Changes: <https://github.com/Moechz/deluge/blob/main/CHANGELOG.md>

“Deluge”, “LinuxServer.io”, “TerraMaster” and “TOS” are trademarks of their respective owners.
This is an independent community package by Moechz, not affiliated with or endorsed by the
Deluge project, LinuxServer.io or TerraMaster.
