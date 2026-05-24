# Joruri GW AlmaLinux 9 / Podman

This is the Phase 5 Podman target for AlmaLinux 9 hosts. It uses an
AlmaLinux 9 base image with Ruby 4.0.4 built by rbenv.

## Host Setup

Install Podman and podman-compose:

```sh
sudo dnf install -y epel-release
sudo dnf install -y podman python3-podman-compose
```

For rootless Podman, make sure subuid/subgid entries exist:

```sh
grep "$(whoami)" /etc/subuid /etc/subgid
```

If missing:

```sh
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
podman system migrate
```

On SELinux Enforcing hosts, `bin/phase5` automatically applies
`docker-compose.selinux.yml`.

## Services

| Service | Purpose | Port |
|---|---|---:|
| `db` | MySQL 5.7 | internal |
| `app-almalinux9-ruby4` | Rails app on AlmaLinux 9 / Ruby 4.0.4 | 3010 |
| `app-almalinux9-ruby4-proxy` | Nginx proxy | 3011 |
| `app-almalinux9-ruby4-worker` | delayed_job worker | internal |
| `app-almalinux9-ruby4-scheduler` | scheduler loop for selected whenever tasks | internal |

## Commands

```sh
bin/podman-phase5 alma-build
bin/podman-phase5 alma-setup
bin/podman-phase5 alma-check
bin/podman-phase5 alma-test
bin/podman-phase5 alma-up
```

Open:

```text
http://localhost:3010/
```

For the proxy / worker / scheduler stack:

```sh
bin/podman-phase5 alma-stack
```

Open the proxy:

```text
http://localhost:3011/
```

## Notes

- Podman builds use `--format docker --platform linux/amd64`.
- Bind mounts from the host are handled by `docker-compose.selinux.yml` on SELinux Enforcing hosts.
- Generated paths are isolated in Podman named volumes.
