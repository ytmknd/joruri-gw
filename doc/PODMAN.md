# Podman Notes

`bin/phase5` can run with either Docker or Podman.

Runtime selection order:

1. `PHASE5_RUNTIME`
2. `--runtime docker|podman`
3. `podman` if available
4. `docker` if available

Examples:

```sh
PHASE5_RUNTIME=podman bin/phase5 alma-check
bin/phase5 --runtime podman alma-check
bin/podman-phase5 alma-check
```

On AlmaLinux 9 with SELinux Enforcing, `bin/phase5` appends
`docker-compose.selinux.yml` to `COMPOSE_FILE` automatically.

If `podman compose` is unavailable, install `podman-compose`:

```sh
sudo dnf install -y epel-release
sudo dnf install -y python3-podman-compose
```
