#!/bin/bash
# launch_receiver.sh
# Tunes this endpoint into its assigned multicast channel
# Channel assignment is based on the last octet of the host IP:
#   192.168.70.11 -> Channel 1 -> 239.1.1.1:1234
#   192.168.70.12 -> Channel 2 -> 239.1.1.2:1234
#   192.168.70.13 -> Channel 3 -> 239.1.1.3:1234

LOG_DIR="/var/log/iptv"
mkdir -p "$LOG_DIR"

# Get this endpoint's IP
HOST_IP=$(hostname -I | awk '{print $1}')

# Calculate channel number from last octet
# .11 - 10 = 1, .12 - 10 = 2, .13 - 10 = 3
LAST_OCTET=$(echo "$HOST_IP" | awk -F. '{print $NF}')
CHANNEL=$((LAST_OCTET - 10))
MULTICAST_ADDR="239.1.1.${CHANNEL}"
PORT="1234"

echo "[$(date)] Endpoint $HOST_IP tuning to Channel $CHANNEL -> udp://@${MULTICAST_ADDR}:${PORT}"

# Launch VLC headless
# --intf dummy     : no GUI
# --no-video       : no display needed
# --repeat         : loop if stream ends
sudo -u iptv vlc \
  --intf dummy \
  --no-video \
  --repeat \
  "udp://@${MULTICAST_ADDR}:${PORT}" \
  >> "${LOG_DIR}/endpoint_ch${CHANNEL}.log" 2>&1

#  To test stream reception manually with ffplay run:
# ffplay -nodisp \
#   -fflags nobuffer \
#   -analyzeduration 2000000 \
#   -probesize 2000000 \
#   -skip_frame noref \
#   udp://@239.1.1.X:1234