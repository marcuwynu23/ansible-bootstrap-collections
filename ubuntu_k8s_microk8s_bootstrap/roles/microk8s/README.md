# microk8s role

Installs [MicroK8s](https://microk8s.io/) on Ubuntu from the snap store: a
`control-plane` (first node) or a `worker` (joins an existing cluster). Enables
addons on the control-plane and joins workers with `microk8s join`.

MicroK8s differs from the k3s/rke2 siblings in three ways worth knowing:

- It is distributed as a **snap**, so it is versioned by **channel**, not by
  version string (Ubuntu ships snapd; no extra setup needed).
- There is **no node-token file**. The join string is minted on demand by
  `microk8s add-node` on an existing node and expires (hence
  `microk8s_join_token_ttl`). `playbooks/install-worker.yml` mints it for you.
- It bundles **its own containerd** inside the snap; a system containerd is
  never used.

## Layout on the target

| Path | Purpose |
|------|---------|
| `/var/snap/microk8s/current/credentials/client.config` | Kubeconfig (also `microk8s config`) |
| `/var/snap/microk8s` | All MicroK8s state (removed on `--purge`) |
| `snap.microk8s.*` | The snap's daemons (kubelet, apiserver, dqlite, cluster agent) |

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `microk8s_node_type` | `control-plane` | `control-plane` or `worker` |
| `microk8s_state` | `present` | `present` installs, `absent` removes |
| `microk8s_channel` | `stable` | Snap channel; pin e.g. `1.30/stable` |
| `microk8s_addons` | `[dns, hostpath-storage, ingress]` | Addons enabled on the control-plane |
| `microk8s_join_token` | `""` | `<master-ip>:25000/<token>` — required for workers |
| `microk8s_join_as_worker` | `true` | Pass `--worker` so the node skips the control plane |
| `microk8s_wait_ready_timeout` | `300` | Seconds to wait for readiness |
| `microk8s_firewall_manage` | `true` | Open MicroK8s firewall ports per node type |
| `microk8s_deregister_from_master` | `true` | Used by `uninstall-worker.yml` |

Workers fail fast with a clear message when `microk8s_join_token` is missing.

## Example

```yaml
# Control-plane:
- hosts: master
  become: true
  roles:
    - role: roles/microk8s
      vars:
        microk8s_node_type: control-plane

# Worker:
- hosts: worker
  become: true
  roles:
    - role: roles/microk8s
      vars:
        microk8s_node_type: worker
        microk8s_join_token: 192.168.1.100:25000/<token>
```

## License

MIT. Author: Mark Wayne.
