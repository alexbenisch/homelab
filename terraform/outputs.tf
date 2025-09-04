output "control_plane_ip" {
  description = "Public IP of the control plane node"
  value       = hcloud_server.control_plane.ipv4_address
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane node"
  value       = "10.0.1.10"
}

output "worker_ips" {
  description = "Public IPs of worker nodes"
  value       = [for worker in hcloud_server.workers : worker.ipv4_address]
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = [for i in range(var.worker_count) : "10.0.1.${20 + i}"]
}

output "k3s_token" {
  description = "k3s cluster token (sensitive)"
  value       = random_password.k3s_token.result
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the k3s cluster"
  value       = var.cluster_name
}

output "network_id" {
  description = "ID of the private network"
  value       = hcloud_network.private.id
}

output "ssh_commands" {
  description = "SSH commands to connect to nodes"
  value = {
    control_plane = "ssh alex@${hcloud_server.control_plane.ipv4_address}"
    workers       = [for worker in hcloud_server.workers : "ssh alex@${worker.ipv4_address}"]
  }
}

output "tailscale_hostnames" {
  description = "Tailscale hostnames for each node"
  value = {
    control_plane = "${var.cluster_name}-control-plane"
    workers       = [for i in range(var.worker_count) : "${var.cluster_name}-worker-${i + 1}"]
  }
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig from control plane"
  value       = "ssh alex@${hcloud_server.control_plane.ipv4_address} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}