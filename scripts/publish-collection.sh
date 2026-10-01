#!/bin/bash

# Check if collection name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <collection-name>"
  echo "Available collections:"
  echo "  - node_app_server_bootstrap"
  echo "  - dotnet_app_server_bootstrap"
  echo "  - php_app_server_bootstrap"
  echo "  - python_app_server_bootstrap"
  echo "  - golang_app_server_bootstrap"
  echo "  - docker_bootstrap"
  echo "  - podman_bootstrap"
  echo "  - kubernetes_helm_bootstrap"
  echo "  - observability_bootstrap"
  echo "  - fedora_k8s_k3s_bootstrap"
  echo "  - fedora_k8s_rke2_bootstrap"
  echo "  - ubuntu_k8s_k3s_bootstrap"
  echo "  - ubuntu_k8s_rke2_bootstrap"
  echo "  - fedora_k8s_microk8s_bootstrap"
  echo "  - ubuntu_k8s_microk8s_bootstrap"
  exit 1
fi

COLLECTION_NAME=$1

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load secrets file if it exists
if [ -f "$SCRIPT_DIR/../.secrets" ]; then
  export $(cat "$SCRIPT_DIR/../.secrets" | grep -v '^#' | xargs)
fi

# Check if collection directory exists (one level up)
if [ ! -d "$SCRIPT_DIR/../$COLLECTION_NAME" ]; then
  echo "Error: Collection directory '$COLLECTION_NAME' not found!"
  exit 1
fi

# Change to collection directory
cd "$SCRIPT_DIR/../$COLLECTION_NAME"

# Build the collection
echo "Building collection..."
ansible-galaxy collection build

# Get the tarball filename
TARBALL=$(ls marcuwynu23-${COLLECTION_NAME}-*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$TARBALL" ]; then
  echo "Error: No collection tarball found!"
  exit 1
fi

# Publish to Ansible Galaxy
echo "Publishing $TARBALL to Ansible Galaxy..."
if [ -z "$ANSIBLE_GALAXY_API_KEY" ]; then
  ansible-galaxy collection publish "$TARBALL"
else
  ansible-galaxy collection publish "$TARBALL" --api-key "$ANSIBLE_GALAXY_API_KEY"
fi

echo "Done!"
