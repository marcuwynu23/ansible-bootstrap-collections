# Ansible Collection - marcuwynu23.fedora_k8s_microk8s_bootstrap

Bootstrap a Kubernetes cluster with [MicroK8s](https://microk8s.io/) on Fedora
virtual machines: OS preparation (including snapd), optional standalone
containerd, and MicroK8s control-plane / worker installation.

> **Heads-up:** MicroK8s is a Canonical product and is officially supported on
> Ubuntu only. This collection makes it work on Fedora by installing **snapd**
> and setting SELinux to `permissive`, both of which are community-supported
> rather than first-class. If you have the choice, prefer
> `marcuwynu23.ubuntu_k8s_microk8s_bootstrap`.

## Contents

| Path | Purpose |
|------|---------|
| `roles/pre` | Fedora node prep: dnf upgrade, base packages, swap off, kernel modules, sysctl, SELinux, firewalld, NetworkManager, **snapd** |
| `roles/containerd` | Optional standalone containerd (MicroK8s bundles its own; disabled by default in the playbooks) |
| `roles/microk8s` | MicroK8s snap install, addons, `microk8s join` / `leave`, channel pinning |
| `playbooks/install-master.yml` | Install the control-plane node (`hosts: master`) |
| `playbooks/install-worker.yml` | Join worker nodes (`hosts: worker`); mints its own join token from the master |
| `playbooks/uninstall-master.yml` / `uninstall-worker.yml` | Remove MicroK8s (`snap remove microk8s --purge`); the worker play also deregisters the node |
| `playbooks/inventory.ini.example` | Key-only SSH inventory template (no passwords, no prompts) |

## Requirements

- Ansible 2.9+ on the controller.
- Fedora targets with Python 3 and SSH key access. Copy
  `playbooks/inventory.ini.example` to `inventory.ini`, set your hosts and
  `ansible_ssh_private_key_file`. The key must already be trusted by the
  targets (public key in the remote user's `authorized_keys`).
- The `pre` role installs snapd for you; SELinux is set to `permissive`, which
  snapd requires on Fedora.

## Quick start

```bash
cp playbooks/inventory.ini.example inventory.ini   # adjust hosts/key
ansible-playbook -i inventory.ini playbooks/install-master.yml
ansible-playbook -i inventory.ini playbooks/install-worker.yml
```

Kubeconfig on any node: `microk8s config`
(`/var/snap/microk8s/current/credentials/client.config`).

## How workers join

K3s and RKE2 hand out a static node-token file; MicroK8s does not. Its join
string is minted on demand by `microk8s add-node` on an existing node and
expires, so `install-worker.yml` delegates to the first `[master]` host, runs
`microk8s add-node`, parses the join string out of the output and passes it to
the workers. That means **the `[master]` group must be in your inventory** for
the worker play, even when you only target workers.

To drive it yourself instead, generate a token on the master and pass it in:

```bash
# on the master:
microk8s add-node
#  -> microk8s join 192.168.1.100:25000/<token>

ansible-playbook -i inventory.ini playbooks/install-worker.yml \
  -e microk8s_join_token=192.168.1.100:25000/<token>
```

## Key variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `microk8s_node_type` | `control-plane` | `control-plane` for the first node, `worker` to join |
| `microk8s_state` | `present` | `present` installs, `absent` uninstalls |
| `microk8s_channel` | `stable` | Snap channel; pin e.g. `1.30/stable` |
| `microk8s_addons` | `[dns, hostpath-storage, ingress]` | Addons enabled on the control-plane (idempotent) |
| `microk8s_join_token` | `""` | `<master-ip>:25000/<token>`; minted automatically when empty |
| `microk8s_join_token_ttl` | `3600` | Lifetime of a minted token in seconds (`0` = never expires) |
| `microk8s_master_host` | first `[master]` host | Which host mints the join token |
| `microk8s_join_as_worker` | `true` | Pass `--worker` so the node skips the control plane |
| `microk8s_wait_ready_timeout` | `300` | Seconds to wait for readiness |
| `microk8s_deregister_from_master` | `true` | On `uninstall-worker.yml`, run `microk8s remove-node` first |
| `containerd_enabled` | `false` (in playbooks) | MicroK8s bundles its own; enable only for a separate system containerd |

Pinning a release:

```bash
ansible-playbook -i inventory.ini playbooks/install-master.yml \
  -e microk8s_channel=1.30/stable
```

## Fedora vs Ubuntu differences

| Fedora collection | Ubuntu collection |
|-------------------|-------------------|
| Installs `snapd` + links `/snap` → `/var/lib/snapd/snap` | snapd is preinstalled; only the socket is ensured |
| SELinux set to `permissive` (snapd requirement) | Not needed — Ubuntu runs AppArmor |
| `firewalld` ports | `ufw` rules (SSH `22/tcp` allowed before enabling) |
| `dnf` packages (`conntrack-tools`) | `apt` packages (`conntrack`) |
| NetworkManager ensured running | Not managed — Ubuntu uses netplan/systemd-networkd |

Both open the same MicroK8s ports: `16443/tcp` (API), `10250`/`10255` (kubelet),
`25000` (cluster agent), `12379` (dqlite), `4789/udp` (VXLAN) and the
`32000-32767` NodePort range. Verify against the upstream
[services and ports](https://microk8s.io/docs/services-and-ports) page for your
MicroK8s version.

## License

MIT. Author: Mark Wayne.
