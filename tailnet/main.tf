terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key"
  type        = string
  sensitive   = true
}

variable "node_count" {
  description = "Number of test nodes"
  type        = number
  default     = 3
}

variable "location" {
  description = "Hetzner Cloud location"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Server type for test nodes"
  type        = string
  default     = "cx22"
}

resource "hcloud_server" "nodes" {
  count       = var.node_count
  name        = "tailscale-node-${count.index}"
  server_type = var.server_type
  image       = "ubuntu-22.04"
  location    = var.location
  ssh_keys    = ["alex@seven"]

  user_data = templatefile("${path.module}/node-template.yaml", {
    tailscale_auth_key = var.tailscale_auth_key
    hostname          = "tailnet-node-${count.index}"
    node_index        = count.index
  })
}

output "node_ips" {
  description = "Public IPs of test nodes"
  value       = [for node in hcloud_server.nodes : node.ipv4_address]
}

output "ssh_commands" {
  description = "SSH commands to connect to nodes"
  value       = [for node in hcloud_server.nodes : "ssh alex@${node.ipv4_address}"]
}

output "tailscale_hostnames" {
  description = "Tailscale hostnames"
  value       = [for i in range(var.node_count) : "tailnet-node-${i}"]
}

output "debug_commands" {
  description = "Commands to check Tailscale logs"
  value = [
    "Check logs: ssh alex@<IP> 'cat /var/log/tailscale-debug.log'",
    "Check status: ssh alex@<IP> 'sudo tailscale status'",
    "Check service: ssh alex@<IP> 'sudo systemctl status tailscaled'"
  ]
}