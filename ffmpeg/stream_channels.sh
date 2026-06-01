#!/bin/bash
# stream_channels.sh
# Starts 3 simultaneous FFmpeg multicast streams

LOG_DIR="/var/log/iptv"

echo "[$(date)] Starting multicast IPTV headend..."

# Channel 1
ffmpeg -re -stream_loop -1 \
  -i /opt/iptv/media/channel_loop.mp4 \
  -c copy -f mpegts \
  'udp://239.1.1.1:1234?pkt_size=1316&ttl=5' \
  >> /var/log/iptv/channel1.log 2>&1 &
echo "[$(date)] Channel 1 started (PID: $!) -> 239.1.1.1:1234"

# Channel 2
ffmpeg -re -stream_loop -1 \
  -i /opt/iptv/media/channel_loop.mp4 \
  -c copy -f mpegts \
  'udp://239.1.1.2:1234?pkt_size=1316&ttl=5' \
  >> /var/log/iptv/channel2.log 2>&1 &
echo "[$(date)] Channel 2 started (PID: $!) -> 239.1.1.2:1234"

# Channel 3
ffmpeg -re -stream_loop -1 \
  -i /opt/iptv/media/channel_loop.mp4 \
  -c copy -f mpegts \
  'udp://239.1.1.3:1234?pkt_size=1316&ttl=5' \
  >> /var/log/iptv/channel3.log 2>&1 &
echo "[$(date)] Channel 3 started (PID: $!) -> 239.1.1.3:1234"

echo "[$(date)] All 3 channels streaming. Logs: ${LOG_DIR}/"

wait