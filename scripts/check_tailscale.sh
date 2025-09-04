#!/bin/bash

set -e

EXPECTED_NODES=$1
TIMEOUT=${2:-60}
CLUSTER_NAME=${3:-homelab}

echo "Checking Tailscale connectivity for $EXPECTED_NODES nodes..."
echo "Timeout: ${TIMEOUT} seconds"

start_time=$(date +%s)
connected_nodes=0

while [ $(($(date +%s) - start_time)) -lt $TIMEOUT ]; do
    # Count nodes with cluster name in Tailscale network
    connected_nodes=$(tailscale status --json | jq -r '.Peer[] | select(.HostName | contains("'$CLUSTER_NAME'")) | .HostName' 2>/dev/null | wc -l || echo 0)
    
    echo "Connected nodes: $connected_nodes/$EXPECTED_NODES"
    
    if [ "$connected_nodes" -ge "$EXPECTED_NODES" ]; then
        echo "✅ All nodes connected successfully!"
        tailscale status | grep "$CLUSTER_NAME"
        exit 0
    fi
    
    echo "Waiting for more nodes... ($(( TIMEOUT - ($(date +%s) - start_time) ))s remaining)"
    sleep 5
done

echo "❌ Timeout reached. Only $connected_nodes/$EXPECTED_NODES nodes connected."
echo "Current Tailscale status:"
tailscale status | grep "$CLUSTER_NAME" || echo "No cluster nodes found"

exit 1