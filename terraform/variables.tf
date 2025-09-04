variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key" {
  description = "Tailscale Auth Key for node authentication"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner Cloud location"
  type        = string
  default     = "nbg1"
}

variable "server_type_control_plane" {
  description = "Server type for k3s control plane"
  type        = string
  default     = "cx22"
}

variable "server_type_worker" {
  description = "Server type for k3s worker nodes"
  type        = string
  default     = "cx22"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "cluster_name" {
  description = "Name of the k3s cluster"
  type        = string
  default     = "homelab"
}