#!/bin/bash
cd /home/container || exit 1

if [ ! -x ./xash ] || [ ! -d ./public ]; then
    echo "First start: copying game files from the image into /home/container (can take a minute)..."
    if ! cp -a /xashds/. /home/container/ || [ ! -x ./xash ]; then
        echo "Copy failed (uid $(id -u)):"; ls -la /home/container; df -h /home/container
        exit 1
    fi
fi
grep -q ' /home/container ' /proc/self/mountinfo || echo "NOTE: /home/container is not a mounted volume, so files will not persist across restarts."

# Browsers connect to the WebRTC UDP port on this IP, so it must be the *public* one.
valid_ip() { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }

IP_ADDR="${PUBLIC_IP}"
if [ -n "${IP_ADDR}" ] && ! valid_ip "${IP_ADDR}"; then
    echo "PUBLIC_IP '${IP_ADDR}' is not an IPv4 address - auto-detecting instead."
    IP_ADDR=""
fi
if [ -z "${IP_ADDR}" ]; then
    IP_ADDR=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)
fi
if valid_ip "${IP_ADDR}"; then
    export IP="${IP_ADDR}"
else
    echo "WARNING: could not determine the public IP - set the PUBLIC_IP variable or remote players cannot connect."
fi

# The web UI is hard-coded to TCP 27016; WebRTC uses UDP on the same number, so one allocation covers both.
export PORT="${SERVER_PORT}"

echo "Starting CS 1.6 web server (web UI: tcp/${SERVER_PORT}, webrtc: udp/${PORT}, public ip: ${IP:-unknown})"

MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")
echo ":/home/container$ ${MODIFIED_STARTUP}"
exec ${MODIFIED_STARTUP}
