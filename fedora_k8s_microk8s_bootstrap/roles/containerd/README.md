# containerd role

Installs and configures standalone containerd on Fedora (`dnf`,
`/etc/containerd/config.toml` with `SystemdCgroup = true`, systemd service).

> **Note:** MicroK8s bundles and manages its own containerd internally, and does
> not use a system-wide one. This role is kept for parity with the k3s/rke2
> sibling collections, where an optional standalone containerd also exists. The
> collection playbooks set `containerd_enabled: false` by default — enable it
> only if you independently want a system containerd on the host.

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `containerd_state` | `present` | `present` installs, `absent` removes |
| `containerd_enabled` | `true` | `false` skips everything (used by the MicroK8s playbooks) |
| `containerd_config_path` | `/etc/containerd/config.toml` | Config file (generated once via `containerd config default`) |
| `containerd_systemd_cgroup` | `true` | Enforce `SystemdCgroup = true` in the config |

## Example

```yaml
- hosts: master
  become: true
  roles:
    - role: roles/containerd
      vars:
        containerd_state: present
```

## License

MIT. Author: Mark Wayne.
