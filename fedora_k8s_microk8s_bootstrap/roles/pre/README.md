# pre role

Fedora OS preparation for MicroK8s Kubernetes nodes. Covers hostname, system
updates, swap, kernel modules, sysctl, SELinux, firewall, NetworkManager, and
the **snapd** setup MicroK8s needs on Fedora. Uses `dnf`/`firewalld`
(no `apt`/`netplan`).

## What it does

- Asserts the target is Fedora / RHEL family.
- Optionally sets the hostname (`pre_hostname`).
- Optionally upgrades all packages (`dnf upgrade`).
- Installs base packages (curl, iptables, socat, conntrack-tools, firewalld, snapd, ...).
- Disables swap at runtime and removes it from `/etc/fstab` (required by Kubernetes).
- Persists/loads `overlay` + `br_netfilter` kernel modules.
- Applies sysctl (`ip_forward`, bridge-nf-call) via `/etc/sysctl.d/99-k8s-microk8s.conf`.
- Sets SELinux mode (default `permissive` — also what snapd needs on Fedora).
- Opens MicroK8s firewall ports (16443 API, 10250/10255 kubelet, 25000 cluster
  agent, 12379 dqlite, 4789/udp VXLAN, 32000-32767 NodePorts).
- Ensures `firewalld` and `NetworkManager` are running.
- Installs snapd, links `/snap` → `/var/lib/snapd/snap`, starts `snapd.socket`,
  and waits for the snap seed to load.

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `pre_hostname` | `""` (skip) | Hostname to set |
| `pre_update_system` | `true` | Run `dnf upgrade` |
| `pre_disable_swap` | `true` | Disable swap now and in fstab |
| `pre_selinux_state` | `permissive` | `permissive` / `enforcing` / `disabled` |
| `pre_firewall_manage` | `true` | Manage firewalld + MicroK8s ports |
| `pre_manage_snap` | `true` | Install/seed snapd (required by MicroK8s on Fedora) |
| `pre_base_packages` | (list) | Packages installed via dnf |
| `pre_kernel_modules` | `[overlay, br_netfilter]` | Modules to persist and load |
| `pre_sysctl_params` | (dict) | Sysctl keys written to `99-k8s-microk8s.conf` |
| `pre_firewall_ports` | (list) | Ports opened when `pre_firewall_manage` is true |

## Example

```yaml
- hosts: master
  become: true
  roles:
    - role: roles/pre
      vars:
        pre_hostname: k8s-master-1
```

## License

MIT. Author: Mark Wayne.
