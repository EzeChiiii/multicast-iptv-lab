#!/bin/bash
# validate_streams.sh
# Uses ffprobe to inspect all 3 multicast channels
# and log stream metadata - codec, resolution, bitrate, format
# Run this after stream_channels.sh to confirm streams are healthy

LOG_DIR="/var/log/iptv"
REPORT="${LOG_DIR}/validation_$(date +%Y%m%d_%H%M%S).log"
TIMEOUT="10"

mkdir -p "$LOG_DIR"

echo "=======================================" | tee "$REPORT"
echo " Multicast IPTV Stream Validation" | tee -a "$REPORT"
echo " $(date)" | tee -a "$REPORT"
echo "=======================================" | tee -a "$REPORT"

PASS=0
FAIL=0

probe_channel() {
  local channel=$1
  local address=$2

  echo "" | tee -a "$REPORT"
  echo "--- Channel ${channel} | udp://@${address} ---" | tee -a "$REPORT"

OUTPUT=$(ffprobe \
    -v quiet \
    -print_format json \
    -show_streams \
    -show_format \
    -timeout "${TIMEOUT}000000" \
    "udp://@${address}" 2>&1)

  if [ $? -ne 0 ] || [ -z "$OUTPUT" ]; then
    echo "  STATUS : FAIL - Stream unreachable" | tee -a "$REPORT"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "  STATUS : PASS" | tee -a "$REPORT"
  PASS=$((PASS + 1))

  # Video info
  VIDEO=$(echo "$OUTPUT" | python3 -c "
import json,sys
data=json.load(sys.stdin)
streams=[s for s in data.get('streams',[]) if s.get('codec_type')=='video']
if streams:
    s=streams[0]
    print(f\"{s.get('codec_name','N/A')} | {s.get('width','?')}x{s.get('height','?')} | {s.get('r_frame_rate','?')} fps\")
else:
    print('No video stream found')
" 2>/dev/null)

  # Audio info
  AUDIO=$(echo "$OUTPUT" | python3 -c "
import json,sys
data=json.load(sys.stdin)
streams=[s for s in data.get('streams',[]) if s.get('codec_type')=='audio']
if streams:
    s=streams[0]
    print(f\"{s.get('codec_name','N/A')} | {s.get('sample_rate','?')} Hz | {s.get('channels','?')} ch\")
else:
    print('No audio stream found')
" 2>/dev/null)

  # Format info
# Format info
# Measure actual bitrate separately
  BITRATE=$(ffprobe \
    -v quiet \
    -select_streams v:0 \
    -show_entries packet=size \
    -of csv=p=0 \
    -read_intervals "%+5" \
    "udp://@${address}" 2>/dev/null | \
    awk '{sum+=$1} END {printf "%d kbps", (sum*8/5)/1000}')

  FORMAT=$(echo "$OUTPUT" | python3 -c "
import json,sys
data=json.load(sys.stdin)
fmt=data.get('format',{})
print(fmt.get('format_name','N/A'))
" 2>/dev/null)

echo "  VIDEO  : $VIDEO" | tee -a "$REPORT"
  echo "  AUDIO  : $AUDIO" | tee -a "$REPORT"
  echo "  FORMAT : $FORMAT | $BITRATE" | tee -a "$REPORT"
}



# Probe all 3 channels
probe_channel 1 "239.1.1.1:1234"
probe_channel 2 "239.1.1.2:1234"
probe_channel 3 "239.1.1.3:1234"

# Summary
echo "" | tee -a "$REPORT"
echo "=======================================" | tee -a "$REPORT"
echo " RESULTS: ${PASS} PASSED | ${FAIL} FAILED" | tee -a "$REPORT"
echo " Report saved: $REPORT" | tee -a "$REPORT"
echo "=======================================" | tee -a "$REPORT"

[ $FAIL -eq 0 ] && exit 0 || exit 1