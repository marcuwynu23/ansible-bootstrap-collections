# Ansible Collection - marcuwynu23.fedora_k8s_upstream_bootstrap

Bootstrap a vanilla upstream Kubernetes cluster with **kubeadm** on Fedora/RHEL virtual machines: OS preparation, containerd CRI, kubeadm/kubelet/kubectl installation from the official Kubernetes yum repositories, and **CNI networking (Flannel/Calico/Cilium/Weave)**.

Fedora counterpart of `marcuwynu23.ubuntu_k8s_upstream_bootstrap` — same roles and playbooks, adapted to RHEL-family tooling (`dnf`, `firewalld`, SELinux).

## Quick Start (5 minutes)

### 1. Prerequisites
- Fedora 38+/39+/40+ or RHEL 9+/Rocky 9+/AlmaLinux 9+ target machines with Python 3
- SSH key access (public key in `authorized_keys` on targets)
- Ansible 2.9+ on controller

### 2. Clone & Configure Inventory
```bash
# Copy example inventory
cp playbooks/inventory.ini.example inventory.ini

# Edit inventory.ini - replace IPs with your servers
# [master] = control-plane node(s)
# [worker] = worker node(s)
```

Example `inventory.ini`:
```ini
[master]
k8s-master-1 ansible_host=192.168.1.10 ansible_user=fedora ansible_ssh_private_key_file=~/.ssh/id_rsa

[worker]
k8s-worker-1 ansible_host=192.168.1.20 ansible_user=fedora ansible_ssh_private_key_file=~/.ssh/id_rsa
k8s-worker-2 ansible_host=192.168.1.21 ansible_user=fedora ansible_ssh_private_key_file=~/.ssh/id_rsa

[k8s:children]
master
worker

[k8s:vars]
ansible_user=fedora
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args=-o PubkeyAuthentication=yes -o PasswordAuthentication=no -o StrictHostKeyChecking=accept-new
```

### 3. Install Everything (Single Command)
```bash
# Install master + CNI (Flannel default) + workers
ansible-playbook -i inventory.ini playbooks/install-master.yml
ansible-playbook -i inventory.ini playbooks/install-worker.yml
```

That's it! Your cluster is ready.

---

## What Gets Installed Automatically

| Component | Details |
|-----------|---------|
| **OS Prep** | Kernel modules, sysctl, swap off, firewall (firewalld), SELinux permissive, packages |
| **Container Runtime** | containerd with CRI plugin + crictl config |
| **Kubernetes** | kubeadm, kubelet, kubectl from official `pkgs.k8s.io` |
| **Control Plane** | `kubeadm init` with HA-ready config |
| **CNI Networking** | Flannel (default), Calico, Cilium, or Weave |
| **Kubeconfig** | Auto-copied to `/root/.kube/config` and `/home/fedora/.kube/config` |
| **Workers** | Auto-join using token from master |

---

## Customization

### Choose CNI Plugin
```bash
# Flannel (default, simplest)
ansible-playbook -i inventory.ini playbooks/install-master.yml -e cni_plugin=flannel

# Calico (requires matching CIDR)
ansible-playbook -i inventory.ini playbooks/install-master.yml \
  -e cni_plugin=calico \
  -e k8s_pod_network_cidr=192.168.0.0/16 \
  -e cni_calico_ipv4pool_cidr=192.168.0.0/16

# Cilium (eBPF, advanced features)
ansible-playbook -i inventory.ini playbooks/install-master.yml -e cni_plugin=cilium

# Weave (encrypted mesh)
ansible-playbook -i inventory.ini playbooks/install-master.yml -e cni_plugin=weave

# No CNI (you'll install manually)
ansible-playbook -i inventory.ini playbooks/install-master.yml -e cni_plugin=none
```

### Pin Kubernetes Version
```bash
# Latest v1.37 (default)
ansible-playbook -i inventory.ini playbooks/install-master.yml

# Specific version
ansible-playbook -i inventory.ini playbooks/install-master.yml \
  -e k8s_major_version=1.36 \
  -e k8s_version=1.36.3-150500.1.1
```

### High Availability (Multi-Master)
```bash
# 1. Set load balancer endpoint (HAProxy/Keepalived/nginx)
# 2. First master
ansible-playbook -i inventory.ini playbooks/install-master.yml \
  -e k8s_control_plane_endpoint=https://10.0.0.100:6443

# 3. Get cert key on first master
kubeadm init phase upload-certs --upload-certs

# 4. Additional masters
ansible-playbook -i inventory.ini playbooks/install-master.yml \
  -e k8s_control_plane_endpoint=https://10.0.0.100:6443 \
  -e k8s_join_token=<from-first-master> \
  -e k8s_discovery_token_ca_cert_hash=sha256:<from-first-master> \
  -e k8s_certificate_key=<from-step-3>
```

---

## Verify & Use

```bash
# Get kubeconfig (already on master at /root/.kube/config)
scp fedora@192.168.1.10:/root/.kube/config ~/.kube/config

# Or use directly on master
kubectl get nodes -o wide

# Check CNI pods
kubectl get pods -A -l k8s-app=flannel
kubectl get pods -A -l k8s-app=calico-node
```

---

## Uninstall (Clean Reset)
```bash
# Remove master + workers completely
ansible-playbook -i inventory.ini playbooks/uninstall-master.yml
ansible-playbook -i inventory.ini playbooks/uninstall-worker.yml
```
Restores OS to pre-install state (firewall, sysctl, swap, SELinux, packages removed).

---

## Playbooks & Inventory

| File | Purpose |
|------|---------|
| `playbooks/install-master.yml` | Install control-plane + CNI |
| `playbooks/install-worker.yml` | Join worker nodes |
| `playbooks/uninstall-master.yml` | Clean uninstall control-plane |
| `playbooks/uninstall-worker.yml` | Clean uninstall workers |
| `playbooks/inventory.ini.example` | Template inventory |

---

## Requirements
- Ansible 2.9+
- Fedora 38+/39+/40+ or RHEL 9+/Rocky 9+/AlmaLinux 9+
- SSH key access (no passwords)
- Python 3 on targets

---

## Key Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_version` | `""` (latest) | Pin version: `1.37.0-150500.1.1` |
| `k8s_major_version` | `""` (auto, 1.37) | Repo major version: `1.37`, `1.36` |
| `k8s_pod_network_cidr` | `10.244.0.0/16` | Pod CIDR (Flannel default) |
| `cni_plugin` | `flannel` | `flannel`, `calico`, `cilium`, `weave`, `none` |
| `cni_version` | `""` (latest) | CNI version pin |
| `k8s_control_plane_endpoint` | `""` (auto) | HA endpoint `host:port` |
| `k8s_kubeadm_api_version` | `v1beta4` | `v1beta4` for ≥1.31, `v1beta3` for ≤1.30 |
| `pre_selinux_state` | `permissive` | SELinux mode during install |

---

## Fedora vs Ubuntu Differences

| Ubuntu | Fedora |
|--------|--------|
| `apt` packages | `dnf` packages |
| `ufw` firewall | `firewalld` |
| AppArmor (default) | SELinux set to `permissive` |
| `containerd` default | `containerd` default |

---

## License
MIT. Author: Mark Wayne.