output "streamer_ip" {
  description = "IP address of the FFmpeg streamer LXC"
  value       = proxmox_virtual_environment_container.streamer.initialization[0].ip_config[0].ipv4[0].address
}

output "streamer_hostname" {
  description = "Hostname of the FFmpeg streamer LXC"
  value       = proxmox_virtual_environment_container.streamer.initialization[0].hostname
}

output "endpoint_ips" {
  description = "IP addresses of the 3 IPTV endpoint LXCs"
  value = [
    for container in proxmox_virtual_environment_container.endpoint :
    container.initialization[0].ip_config[0].ipv4[0].address
  ]
}

output "endpoint_hostnames" {
  description = "Hostnames of the 3 IPTV endpoint LXCs"
  value = [
    for container in proxmox_virtual_environment_container.endpoint :
    container.initialization[0].hostname
  ]
}

output "desktop_ip" {
  description = "IP address of the Ubuntu desktop VM"
  value       = "192.168.70.20"
}

output "desktop_hostname" {
  description = "Hostname of the Ubuntu desktop VM"
  value       = proxmox_virtual_environment_vm.desktop.name
}