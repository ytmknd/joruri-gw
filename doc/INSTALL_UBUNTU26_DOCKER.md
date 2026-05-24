# Joruri GW Ubuntu 26.04 / Docker

This is the Phase 5 Docker target for the Rails 8 / Ruby 4 runtime.

## Services

| Service | Purpose | Port |
|---|---|---:|
| `db` | MySQL 5.7 | internal |
| `app-ubuntu26-ruby4` | Rails app on Ubuntu 26.04 / Ruby 4.0.4 | 3008 |
| `app-ubuntu26-ruby4-proxy` | Nginx proxy | 3009 |
| `app-ubuntu26-ruby4-worker` | delayed_job worker | internal |
| `app-ubuntu26-ruby4-scheduler` | scheduler loop for selected whenever tasks | internal |

The historical `app-phase5` service remains available on port `3006`.

## Commands

```sh
bin/docker-phase5 ubuntu26-build
bin/docker-phase5 ubuntu26-setup
bin/docker-phase5 ubuntu26-check
bin/docker-phase5 ubuntu26-test
bin/docker-phase5 ubuntu26-up
```

Open:

```text
http://localhost:3008/
```

For the proxy / worker / scheduler stack:

```sh
bin/docker-phase5 ubuntu26-stack
```

Open the proxy:

```text
http://localhost:3009/
```

## Existing Compatibility Commands

These still target `app-phase5`:

```sh
bin/docker-phase5 build
bin/docker-phase5 setup
bin/docker-phase5 check
bin/docker-phase5 test
bin/docker-phase5 smoke
bin/docker-phase5 up
```

## Notes

- The source tree is mounted at `/var/share/jorurigw`.
- Large generated paths use Docker named volumes: `vendor/bundle`, `.bundle`, `log`, `tmp`, `public/assets`, and `upload`.
- The container creates/runs the application as `joruri:joruri` with UID/GID `1000`.
- `docker/ubuntu26-ruby4/Dockerfile` is self-contained and no longer depends on the `joruri-mail` image.
