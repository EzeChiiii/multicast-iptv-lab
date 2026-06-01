# Multicast IPTV Lab

A fully automated venue-style multicast IPTV streaming lab built on Proxmox VE.
Infrastructure provisioned with **Terraform**, configured with **Ansible**,
streamed with **FFmpeg**, validated with **FFprobe**, and received by **FFplay/VLC** endpoints.

---

## Architecture

<img width="514" height="516" alt="Screenshot 2026-06-01 at 12 39 59 AM" src="https://github.com/user-attachments/assets/c99bdf7f-73df-470c-a0b7-779f00b0446e" />


<img width="1441" height="506" alt="Screenshot 2026-06-01 at 1 09 25 AM" src="https://github.com/user-attachments/assets/229e35f6-511a-43f4-8a4b-e0040ce87980" />

---

## Channel Map

| Channel | Multicast Address | Port | Endpoint |
|---------|-------------------|------|----------|
| CH1 | 239.1.1.1 | 1234 | iptv-endpoint-1 @ 192.168.70.11 |
| CH2 | 239.1.1.2 | 1234 | iptv-endpoint-2 @ 192.168.70.12 |
| CH3 | 239.1.1.3 | 1234 | iptv-endpoint-3 @ 192.168.70.13 |

---

## Project Structure

<img width="538" height="395" alt="Screenshot 2026-06-01 at 12 46 11 AM" src="https://github.com/user-attachments/assets/a211bce0-4c6a-4ee3-b805-09d7452641ef" />

---

## Tools Used

| Tool | Version | Role |
|------|---------|------|
| Terraform | 1.15.5 | Provisions 4 LXC containers on Proxmox |
| Ansible | 2.20.6 | Installs FFmpeg, VLC, deploys all scripts |
| FFmpeg | 7.1.4 | Multicast headend — 3 simultaneous UDP streams |
| FFprobe | 7.1.4 | Stream validation — codec, resolution, bitrate |
| FFplay | 7.1.4 | Stream reception testing on endpoints |
| VLC headless | 3.x | Endpoint receiver — sends real IGMP join reports |
| Proxmox VE | 8.x | Hypervisor hosting all 4 LXCs |
| FortiGate 60F | — | VLAN 70 segmentation, IGMP snooping |

---

## Prerequisites

- Proxmox VE with a Debian 13 LXC template downloaded
- VLAN 70 configured on FortiGate with IGMP snooping enabled on FortiSwitch
- Terraform >= 1.0 installed on your workstation
- Ansible installed on your workstation
- SSH key pair for LXC access

---

## Deployment

### Step 1 — Provision LXC infrastructure with Terraform

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox credentials

terraform init
terraform plan
terraform apply
```

Creates 4 LXCs on VLAN 70:
- `iptv-streamer` @ 192.168.70.10 (4 cores, 4GB RAM)
- `iptv-endpoint-1` @ 192.168.70.11 (2 cores, 1GB RAM)
- `iptv-endpoint-2` @ 192.168.70.12 (2 cores, 1GB RAM)
- `iptv-endpoint-3` @ 192.168.70.13 (2 cores, 1GB RAM)

### Step 2 — Configure all machines with Ansible

```bash
cd ansible/
ansible-playbook -i inventory.ini deploy_streamer.yml
ansible-playbook -i inventory.ini deploy_endpoints.yml
```

### Step 3 — Add source media to streamer

```bash
scp your_video.mp4 root@192.168.70.10:/opt/iptv/media/channel_loop.mp4
```

### Step 4 — Start streaming

```bash
ssh root@192.168.70.10 "systemctl start iptv-stream"

```
<img width="1009" height="314" alt="Screenshot 2026-06-01 at 1 11 27 AM" src="https://github.com/user-attachments/assets/37ddb7ca-ae63-4a59-9eca-206b85684c1a" />

**Systemd service status — 3 FFmpeg processes running:**

<img width="1336" height="72" alt="Screenshot 2026-06-01 at 1 10 17 AM" src="https://github.com/user-attachments/assets/abc74918-b841-4053-8ec6-384130e1926a" />


### Step 5 — Validate streams with FFprobe

```bash
ssh root@192.168.70.10 "/opt/iptv/scripts/validate_streams.sh"
```

Expected output:

<img width="588" height="408" alt="Screenshot 2026-06-01 at 12 44 41 AM" src="https://github.com/user-attachments/assets/2e9dfad8-62a4-4f73-81c3-e834d5926436" />

### Step 6 — Test reception with FFplay on endpoints

```bash
# Endpoint 1
ssh root@192.168.70.11 "ffplay -nodisp -fflags nobuffer \
  -analyzeduration 2000000 -probesize 2000000 \
  -skip_frame noref udp://@239.1.1.1:1234"

# Endpoint 2
ssh root@192.168.70.12 "ffplay -nodisp -fflags nobuffer \
  -analyzeduration 2000000 -probesize 2000000 \
  -skip_frame noref udp://@239.1.1.2:1234"

# Endpoint 3
ssh root@192.168.70.13 "ffplay -nodisp -fflags nobuffer \
  -analyzeduration 2000000 -probesize 2000000 \
  -skip_frame noref udp://@239.1.1.3:1234"
```

<img width="689" height="326" alt="Screenshot 2026-06-01 at 1 11 56 AM" src="https://github.com/user-attachments/assets/bcb38a69-4a5e-4ae2-b77c-acfab526497f" />


### Step 7 — Verify IGMP group membership

```bash
for i in 11 12 13; do
  echo "--- Endpoint 192.168.70.$i ---"
  ssh root@192.168.70.$i "ip maddr show eth0"
done
```

Expected — each endpoint joined its multicast group:

inet  239.1.1.1   # endpoint 1
inet  239.1.1.2   # endpoint 2
inet  239.1.1.3   # endpoint 3


<img width="372" height="524" alt="Screenshot 2026-06-01 at 12 50 47 AM" src="https://github.com/user-attachments/assets/7497b1ac-ee80-4e82-a859-9c23905dcf92" />
---

## Troubleshooting

### FFplay SDL display error on headless LXC
FFplay requires SDL to render video. On headless LXCs with no display server,
FFplay successfully decodes the stream but fails at the render stage with
`Failed to open filtergraph`. This is expected behavior — the stream is healthy.
Use FFprobe to validate stream health and VLC headless for endpoint reception.

### Multiple FFmpeg processes running
If systemd restarts the service without killing existing processes:
```bash
ssh root@192.168.70.10 "pkill -9 ffmpeg && systemctl restart iptv-stream"
```

### Stream shows corrupt packets on loop
Source file must be encoded with fixed keyframe intervals for clean looping.
Re-encode with:
```bash
ffmpeg -i input.mp4 \
  -c:v libx264 -preset fast -b:v 4M \
  -x264-params keyint=60:min-keyint=60 \
  -c:a aac -b:a 128k \
  -f mpegts output.mp4
```

### High CPU usage
Using `-c copy` instead of `-c:v libx264` drops CPU from ~130% to ~3% per channel
when the source is already H.264. Only re-encode when the source needs transcoding.

---


