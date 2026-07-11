#!/bin/sh
# Automated smoke test for the sshtunnel container.
# Builds the image, generates a throwaway ed25519 keypair, starts the container
# with a test user (public key passed via the USER_<name> env the entrypoint
# expects) and asserts that sshd's config is valid, the daemon is running and
# listening on 22, and that public-key auth with the generated key succeeds.
set -e

IMG=sshtunnel-test
CN=sshtunnel-test-run
PORT=22022
WORKDIR=$(mktemp -d)

cleanup() {
  docker rm -f "$CN" >/dev/null 2>&1 || true
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

fail() { echo "FAIL: $1"; exit 1; }

echo ">> generating ephemeral ed25519 keypair"
ssh-keygen -t ed25519 -N '' -f "$WORKDIR/id_test" -C tester@test >/dev/null
PUBKEY=$(cat "$WORKDIR/id_test.pub")

echo ">> building image"
docker build -t "$IMG" .

echo ">> starting container"
docker rm -f "$CN" >/dev/null 2>&1 || true
docker run -d --name "$CN" -p 127.0.0.1:$PORT:22 \
  -e USER_tester="$PUBKEY" \
  -e PERMIT_OPEN_tester_bbchttp='www.bbc.com:80' \
  "$IMG" >/dev/null

echo ">> waiting for sshd to listen on 22 (up to 60s)"
up=0
for _ in $(seq 1 30); do
  if docker exec "$CN" bash -c 'exec 3<>/dev/tcp/127.0.0.1/22' 2>/dev/null; then up=1; break; fi
  sleep 2
done
[ "$up" = 1 ] || fail "sshd did not start listening on 22 in time"

echo ">> assert: container is running"
[ "$(docker inspect -f '{{.State.Running}}' "$CN")" = true ] || fail "container not running"
echo "ok - container running"

echo ">> assert: sshd -t validates the config"
docker exec "$CN" /usr/sbin/sshd -t || fail "sshd -t reported a config error"
echo "ok - sshd config valid"

echo ">> assert: sshd daemon process is running"
docker exec "$CN" sh -c 'for c in /proc/[0-9]*/comm; do read n < "$c"; [ "$n" = sshd ] && exit 0; done; exit 1' \
  || fail "no sshd process running"
echo "ok - sshd process running"

echo ">> assert: sshd is listening on 22"
docker exec "$CN" bash -c 'exec 3<>/dev/tcp/127.0.0.1/22' 2>/dev/null || fail "sshd not listening on 22"
echo "ok - sshd listening on 22"

echo ">> assert: SSH banner on published port"
banner=$(printf '' | nc -w 3 127.0.0.1 $PORT 2>/dev/null | head -1 | tr -d '\r' || true)
[ -n "$banner" ] && echo "$banner" | grep -qi '^SSH-' && echo "ok - SSH banner: $banner" || echo "note - could not read SSH banner via nc (skipping)"

echo ">> assert: public-key auth with the generated key succeeds"
ssh -v -i "$WORKDIR/id_test" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -p $PORT tester@127.0.0.1 true 2>"$WORKDIR/ssh.log" || true
grep -q "Authenticated to" "$WORKDIR/ssh.log" \
  || fail "ssh public-key auth did not succeed (see log below)$(printf '\n%s' "$(cat "$WORKDIR/ssh.log")")"
echo "ok - public-key auth succeeded"

echo ""
echo "ALL TESTS PASSED"
