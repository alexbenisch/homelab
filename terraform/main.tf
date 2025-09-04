terraform {
  required_version = ">= 1.5"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Create private network
resource "hcloud_network" "private" {
  name     = "${var.cluster_name}-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Generate random token for k3s cluster
resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

# Control plane server
resource "hcloud_server" "control_plane" {
  name        = "${var.cluster_name}-control-plane"
  server_type = var.server_type_control_plane
  image       = "ubuntu-22.04"
  location    = var.location
  ssh_keys    = ["alex@seven"]

  network {
    network_id = hcloud_network.private.id
    ip         = "10.0.1.10"
  }

  user_data = templatefile("${path.module}/../templates/control-plane.yaml", {
    tailscale_auth_key = var.tailscale_auth_key
    hostname           = "${var.cluster_name}-control-plane"
    private_ip         = "10.0.1.10"
  })

  depends_on = [hcloud_network_subnet.private]
}

# Worker nodes
resource "hcloud_server" "workers" {
  count       = var.worker_count
  name        = "${var.cluster_name}-worker-${count.index + 1}"
  server_type = var.server_type_worker
  image       = "ubuntu-22.04"
  location    = var.location
  ssh_keys    = ["alex@seven"]

  network {
    network_id = hcloud_network.private.id
    ip         = "10.0.1.${20 + count.index}"
  }

  user_data = templatefile("${path.module}/../templates/worker.yaml", {
    tailscale_auth_key = var.tailscale_auth_key
    hostname           = "${var.cluster_name}-worker-${count.index + 1}"
    private_ip         = "10.0.1.${20 + count.index}"
    control_plane_ip   = "10.0.1.10"
    k3s_token          = random_password.k3s_token.result
  })

  depends_on = [hcloud_server.control_plane]
}

# Check Tailscale connectivity after deployment
resource "null_resource" "tailscale_check" {
  depends_on = [hcloud_server.control_plane, hcloud_server.workers]
  
  provisioner "local-exec" {
    command = "${path.module}/../scripts/check_tailscale.sh ${var.worker_count + 1} 60 ${var.cluster_name}"
    
    on_failure = fail
  }
  
  # Trigger re-check if servers change
  triggers = {
    control_plane_id = hcloud_server.control_plane.id
    worker_ids = join(",", [for worker in hcloud_server.workers : worker.id])
  }
}

# Auto-destroy on Tailscale failure
resource "null_resource" "auto_destroy_on_failure" {
  depends_on = [null_resource.tailscale_check]
  
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Tailscale check failed - servers will be destroyed'"
  }
}