# pre role

Ubuntu OS preparation for MicroK8s Kubernetes nodes. Covers hostname, system
updates, swap, kernel modules, sysctl, firewall, and the snapd socket MicroK8s
needs. Uses `apt`/`ufw`; Ubuntu runs AppArmor, so there are no SELinux tasks.

## What it does

- Asserts the target is Ubuntu / Debian family.
- Optionally sets the hostname (`pre_hostname`).
- Optionally upgrades all packages (`apt upgrade`).
- Installs base packages (curl, iptables, socat, conntrack, ufw, snapd, ...).
- Allows SSH through ufw *before* enabling it, so you are never locked out.
- Disables swap at runtime and removes it from `/etc/fstab` (required by Kubernetes).
- Persists/loads `overlay` + `br_netfilter` kernel modules.
- Applies sysctl (`ip_forward`, bridge-nf-call) via `/etc/sysctl.d/99-k8s-microk8s.conf`.
- Opens MicroK8s firewall ports (16443 API, 10250/10255 kubelet, 25000 cluster
  agent, 12379 dqlite, 4789/udp VXLAN, 32000-32767 NodePorts).
- Ensures `snapd.socket` is running and the snap seed has loaded.

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `pre_hostname` | `""` (skip) | Hostname to set |
| `pre_update_system` | `true` | Run `apt upgrade` |
| `pre_disable_swap` | `true` | Disable swap now and in fstab |
| `pre_firewall_manage` | `true` | Manage ufw + MicroK8s ports |
| `pre_firewall_allow_ssh_port` | `22/tcp` | Allowed before ufw is enabled (`""` skips) |
| `pre_manage_snap` | `true` | Ensure snapd/socket for MicroK8s |
| `pre_base_packages` | (list) | Packages installed via apt |
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
