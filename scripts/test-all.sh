#!/bin/bash
# Test all collections syntax
echo "Testing all collections syntax..."

# Array of all collections
COLLECTIONS=(
  "node_app_server_bootstrap"
  "dotnet_app_server_bootstrap"
  "php_app_server_bootstrap"
  "python_app_server_bootstrap"
  "golang_app_server_bootstrap"
  "docker_bootstrap"
  "podman_bootstrap"
  "kubernetes_helm_bootstrap"
  "observability_bootstrap"
  "fedora_k8s_k3s_bootstrap"
  "fedora_k8s_rke2_bootstrap"
  "ubuntu_k8s_k3s_bootstrap"
  "ubuntu_k8s_rke2_bootstrap"
  "fedora_k8s_microk8s_bootstrap"
  "ubuntu_k8s_microk8s_bootstrap"
)

# Function to test a single collection
test_collection() {
  local COLLECTION="$1"
  echo -e "\nTesting $COLLECTION..."
  
  cd "$(dirname "$0")/../$COLLECTION" || return

  # App-server style collections: tests/install-check.yml + uninstall-check.yml
  if [ -f tests/install-check.yml ]; then
    # Test install playbook
    echo "  - install-check.yml"
    if ansible-playbook tests/install-check.yml --syntax-check; then
      echo "  ✓ install-check.yml OK"
    else
      echo "  ✗ install-check.yml FAILED"
      return 1
    fi

    # Test uninstall playbook
    echo "  - uninstall.yml"
    if ansible-playbook tests/uninstall-check.yml --syntax-check; then
      echo "  ✓ uninstall-check.yml OK"
    else
      echo "  ✗ uninstall-check.yml FAILED"
      return 1
    fi
  else
    # K8s style collections: install/uninstall master/worker playbooks
    for PLAYBOOK in install-master install-worker uninstall-master uninstall-worker; do
      echo "  - playbooks/${PLAYBOOK}.yml"
      if ansible-playbook "playbooks/${PLAYBOOK}.yml" --syntax-check; then
        echo "  ✓ playbooks/${PLAYBOOK}.yml OK"
      else
        echo "  ✗ playbooks/${PLAYBOOK}.yml FAILED"
        return 1
      fi
    done
  fi

  echo "  ✓ $COLLECTION OK"
  cd - > /dev/null || return
}

# Test all collections
ALL_OK=0
for COLLECTION in "${COLLECTIONS[@]}"; do
  if ! test_collection "$COLLECTION"; then
    ALL_OK=1
  fi
done

# Summary
if [ $ALL_OK -eq 0 ]; then
  echo -e "\n✅ All collections passed syntax checks!"
else
  echo -e "\n❌ Some collections failed syntax checks!"
  exit 1
fi
