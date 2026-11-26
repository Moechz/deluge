#!/bin/sh
# ===========================================================================
# Entrypoint wrapper for the LinuxServer.io Deluge image.
#
# The image is used unmodified, this wrapper only runs before /init:
#
#   1. umask 027 - every file Deluge writes (config, resume data, log, torrent
#      payload) is created without group/world write access instead of the
#      image's default 022 (finding S11).
#   2. /run is a tmpfs owned by uid 1000 (see docker-compose.yml). Recreate the
#      socket temp dir the image expects there, with owner-only access.
#   3. Tighten /config: it holds the Web UI credential hash (config/auth) and
#      the daemon settings, so the tree is set to owner-only (0700 dirs, 0600
#      files). Only files this uid owns are changed; a root-owned entry left by
#      the platform is skipped instead of aborting the start-up.
#   4. /downloads is the user's payload and stays readable by the group, so a
#      shared download folder keeps working while nothing is world writable.
#
# The script must not contain a literal double dollar sign (the packaging step
# uses it as the escape sequence) and is executed as uid 1000, never as root.
# ===========================================================================
set -u

umask 027

if [ -d /run ]; then
    mkdir -p /run/deluged-temp 2>/dev/null || true
    chmod 0700 /run/deluged-temp 2>/dev/null || true
fi

if [ -d /config ]; then
    find /config -xdev -exec chmod go-rwx {} + 2>/dev/null || true
    chmod 0700 /config 2>/dev/null || true
fi

if [ -d /downloads ]; then
    chmod 0750 /downloads 2>/dev/null || true
fi

exec /init
