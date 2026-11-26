#!/usr/bin/env bash
# ===========================================================================
# Functional smoke test for the Deluge TOS package.
#
# Usage:  bash test/smoke.sh [http://127.0.0.1:8020]
#
#   DELUGE_PASSWORD   Web UI password (default: deluge, the upstream first-run
#                     password this package documents and does not change)
#
# It proves what a BitTorrent client must do after installation, not just that
# a port answers:
#   1. the Web UI page loads through the published port (the F7 regression),
#   2. a wrong password is rejected, so authentication is really enforced,
#   3. the documented default password logs in,
#   4. the Web UI reaches the local daemon (web.get_hosts / web.connect),
#   5. the daemon reports its version,
#   6. a .torrent can be added through the API and shows up in the torrent
#      list with the expected name (the core "add a task" flow),
#   7. the test torrent is removed again.
#
# Exit code 0 only when every check passes. Any non-zero exit fails the gate.
# No network access to a tracker is required: the torrent is generated locally
# and its announce URL points at a closed local port, so nothing is uploaded.
# ===========================================================================
set -u

BASE="${1:-http://127.0.0.1:8020}"
BASE="${BASE%/}"
PW="${DELUGE_PASSWORD:-deluge}"
COOKIE="$(mktemp)"
BODY="$(mktemp)"
TORRENT="$(mktemp)"
FAIL=0
HASH=""

say() { printf '  [smoke] %s\n' "$*"; }
ok()  { printf '  [ OK ] %s\n' "$*"; }
bad() { printf '  [FAIL] %s\n' "$*"; FAIL=1; }

rpc() {  # rpc <method> <json-params-array>
  local method="$1" params="${2:-[]}"
  local payload
  payload="$(python3 - "$method" "$params" <<'PY'
import json, sys
print(json.dumps({"id": 1, "method": sys.argv[1], "params": json.loads(sys.argv[2])}))
PY
)" || return 1
  curl -sS -m 20 -b "$COOKIE" -c "$COOKIE" -H 'Content-Type: application/json' \
    -X POST --data-binary "$payload" "$BASE/json" -o "$BODY" 2>/dev/null
}

jget() {  # jget <python-expression over r/e> -> prints value or empty
  python3 - "$BODY" "$1" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(1)
r, e = d.get("result"), d.get("error")
v = eval(sys.argv[2],
             {"__builtins__": {"isinstance": isinstance, "len": len, "str": str,
                              "int": int, "float": float, "list": list,
                              "dict": dict, "bool": bool}},
             {"r": r, "e": e, "d": d})
print("" if v is None else v)
PY
}

cleanup() {
  if [ -n "$HASH" ] && [ -s "$COOKIE" ]; then
    rpc core.remove_torrent "[\"$HASH\", false]" >/dev/null 2>&1 || true
  fi
  rm -f "$COOKIE" "$BODY" "$TORRENT"
}
trap cleanup EXIT

# --- 1. page -----------------------------------------------------------------
CODE="$(curl -sS -m 15 -o "$BODY" -w '%{http_code}' "$BASE/" 2>/dev/null || printf '000')"
SIZE="$(wc -c < "$BODY" 2>/dev/null | tr -d ' ')"
if [ "$CODE" = "200" ] && [ "${SIZE:-0}" -gt 500 ] && grep -qi 'deluge' "$BODY"; then
  ok "Web UI page loads through the published port (HTTP 200, ${SIZE} bytes)"
else
  bad "Web UI page missing or empty (HTTP ${CODE}, ${SIZE:-0} bytes)"
fi

# --- 2. authentication is enforced -------------------------------------------
rpc auth.login '["tos-smoke-wrong-password"]' || true
WRONG="$(jget 'r')"
if [ "$WRONG" = "False" ]; then
  ok "wrong password rejected (auth is enforced)"
else
  bad "wrong password was not rejected (result=$WRONG)"
fi

# --- 3. documented default password -----------------------------------------
rpc auth.login "[\"$PW\"]" || true
GOOD="$(jget 'r')"
if [ "$GOOD" = "True" ]; then
  ok "Web UI login accepted with the documented password"
else
  bad "Web UI login failed (result=$GOOD, error=$(jget 'e'))"
  echo "SMOKE FAILED"; exit 1
fi

# --- 4. web UI reaches the daemon -------------------------------------------
rpc web.get_hosts '[]' || true
HOST_ID="$(jget 'r[0][0] if isinstance(r, list) and r else None')"
if [ -n "$HOST_ID" ]; then
  ok "web UI knows the local daemon (host ${HOST_ID:0:8}...)"
else
  bad "web.get_hosts returned no local daemon (result=$(jget 'r'))"
fi

rpc web.connect "[\"$HOST_ID\"]" || true
METHODS="$(jget 'len(r) if isinstance(r, list) else 0')"
if [ "${METHODS:-0}" -gt 10 ]; then
  ok "web.connect attached to the daemon (${METHODS} core methods)"
else
  bad "web.connect failed (result=$(jget 'r'), error=$(jget 'e'))"
fi

rpc daemon.get_version '[]' || true
VER="$(jget 'r')"
case "$VER" in
  2.*) ok "daemon reports version ${VER}" ;;
  *)   bad "daemon.get_version returned '${VER}'" ;;
esac

# --- 5. add a task and read it back -----------------------------------------
python3 - "$TORRENT" <<'PY'
# Minimal valid .torrent: one 23-byte file, one SHA-1 piece, announce on a
# closed local port so adding it cannot upload anything.
import hashlib, sys
payload = b"deluge-tos-smoke-payload\n"
piece = hashlib.sha1(payload).digest()
def s(b): return str(len(b)).encode() + b":" + b
info = (b"d" + s(b"length") + b"i" + str(len(payload)).encode() + b"e" + s(b"name") +
        s(b"tos-smoke.txt") + s(b"piece length") + b"i16384e" + s(b"pieces") + s(piece) + b"e")
tor = b"d" + s(b"announce") + s(b"http://127.0.0.1:1/announce") + s(b"info") + info + b"e"
open(sys.argv[1], "wb").write(tor)
PY
ADDED="$(python3 - "$TORRENT" <<'PY'
import base64, json, sys
print(json.dumps([ "tos-smoke.torrent",
                   base64.b64encode(open(sys.argv[1], "rb").read()).decode(), {} ]))
PY
)"
rpc core.add_torrent_file "$ADDED" || true
HASH="$(jget 'r')"
if printf '%s' "$HASH" | grep -Eq '^[0-9a-f]{40}$'; then
  ok "torrent accepted by the daemon (hash ${HASH:0:8}...)"
else
  bad "core.add_torrent_file failed (result=$HASH, error=$(jget 'e'))"
  HASH=""
fi

if [ -n "$HASH" ]; then
  rpc core.get_torrents_status '[{}, ["name", "state"]]' || true
  NAME="$(python3 - "$BODY" "$HASH" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    print((d.get("result") or {}).get(sys.argv[2], {}).get("name", ""))
except Exception:
    pass
PY
)"
  if [ "$NAME" = "tos-smoke.txt" ]; then
    ok "the added task is listed by the daemon (${NAME})"
  else
    bad "the added task is not in the torrent list (name='${NAME}')"
  fi
fi

if [ "$FAIL" = 0 ]; then
  echo "SMOKE OK"
  exit 0
fi
echo "SMOKE FAILED"
exit 1
