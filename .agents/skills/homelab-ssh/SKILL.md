---
name: homelab-ssh
description: "Connect to and safely administer the user's `homelab` host over Tailscale SSH. Use when a request mentions `homelab`, `root@homelab`, `superuser@homelab`, the Execsoft Matrix stack, Synapse, Element Web, Caddy, or Docker services on this host. Covers role-specific direct SSH access, validated configuration changes, and Matrix privacy controls."
---

# Homelab SSH

## Connect

Use the local 1Password SSH Agent through the dedicated `Host homelab` entry in `~/.ssh/config`. That entry pins the real 1Password agent socket, `~/.ssh/homelab.pub`, and `IdentitiesOnly yes`; do not depend on the inherited `$SSH_AUTH_SOCK`, which can be stale in an agent session.

Before the first connection in a session, verify the effective host settings:

```bash
ssh -G homelab | grep -E '^(hostname|user|identityagent|identityfile|identitiesonly) '
```

Expect `identityagent` to point to the 1Password socket, `identityfile ~/.ssh/homelab.pub`, and `identitiesonly yes`.

Choose the SSH account before connecting:

| Task scope | Account | Command |
|---|---|---|
| Root-owned files, `/etc`, `/opt`, Docker, systemd, Caddy, or service administration | `root` | `ssh -o ConnectTimeout=15 root@homelab` |
| Files and commands that must run in the unprivileged user's own context | `superuser` | `ssh -o ConnectTimeout=15 superuser@homelab` |

For root actions, connect directly as `root`; do not connect as `superuser` and then invoke `sudo` out of habit. Use `-tt` only when an interactive terminal is actually required.

```bash
ssh -o ConnectTimeout=15 root@homelab
```

If connection fails, distinguish network errors from authentication failures. Do not retry with unrestricted agent identities: that causes `Too many authentication failures`.

## Privileged access

Direct `root@homelab` access needs neither `sudo` nor 1Password. Do not read from 1Password or run `sudo -n -v` preemptively for root-scoped work.

For a command that truly must be launched from a `superuser` session with sudo, first check whether a sudo timestamp is already valid. Only if the command requires sudo and the check reports that authentication is required may you use the 1Password reference `op://Hobby/Execsoft Server/password` through the `$1password` skill. Provide it to `sudo -S -v` only through stdin. Never print, save, or place the password in command arguments, shell history, configuration, or tool output.

Use the account whose permissions match the task instead of escalating unnecessarily.

## Service map

| Component | Location or command |
|---|---|
| Compose project | `/opt/element/docker-compose.yml` |
| Synapse configuration | `/opt/element/synapse/homeserver.yaml` |
| Element Web configuration | `/opt/element/element-web/config.json` |
| Caddy configuration | `/etc/caddy/Caddyfile` |
| Stack status | `docker compose -f /opt/element/docker-compose.yml ps` |
| Synapse logs | `docker compose -f /opt/element/docker-compose.yml logs --tail=100 synapse` |

Service commands assume a direct `root@homelab` connection. Synapse, Element Web and PostgreSQL are Docker services named `synapse`, `element-web` and `postgres`. Their host ports are loopback-bound; Caddy is the public reverse proxy.

## Change workflow

1. Inspect the current configuration and service status before changing anything.
2. Back up each file in place with `cp -a <file> <file>.before-<UTC timestamp>`.
3. Make the smallest change that satisfies the request.
4. Validate before restarting:

   ```bash
   docker compose -f /opt/element/docker-compose.yml exec -T synapse \
     python -m synapse.config -c /data/homeserver.yaml

   jq -e . /opt/element/element-web/config.json >/dev/null
   ```

5. Restart only the affected service:

   ```bash
   docker compose -f /opt/element/docker-compose.yml restart synapse
   docker compose -f /opt/element/docker-compose.yml restart element-web
   ```

6. Verify both client availability and federation isolation:

   ```bash
   curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:11000/_matrix/client/versions
   curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:11000/_matrix/federation/v1/version
   ```

   Expect `200` for the client endpoint and `404` for the federation endpoint.

7. Document every material host change before handoff:

   - Append a concise, factual entry to `/root/BREADCRUMBS.md` immediately after the change. Include time, files touched, affected services or commands, verification, and follow-up work.
   - Update `/root/MANUAL.md` in the same task so operational instructions match the current state: URLs, ports, config paths, access model, commands, and security-relevant behavior where applicable.
   - Do not state that documentation was updated until both files have been verified at their final paths.

## Matrix privacy baseline

Keep these Synapse controls in place unless the user explicitly asks to reopen federation:

```yaml
federation_domain_whitelist: []
allow_profile_lookup_over_federation: false
allow_public_rooms_over_federation: false
trusted_key_servers: []
url_preview_enabled: false
```

The HTTP listener must expose `client` only, not `federation`. Element Web must not set `m.identity_server`, integration-manager, Jitsi or Element Call URLs by default. Keep `disable_custom_urls: true`, `disable_3pid_login: true` and `enable_client_well_known_lookups: false` when the instance is intended to remain private.

Existing Element Desktop and mobile clients can retain identity-server and integration-manager choices locally. Those must be disabled on every client under **Settings → Security & Privacy**; Synapse cannot erase that local state remotely.

## Guardrails

- Treat firewall, Caddy ingress, public DNS, SSH configuration, account registration and Tailscale ACL changes as availability-sensitive. State their impact and get explicit user authorization before applying them.
- The host currently has public Caddy listeners and SSH on all interfaces. Do not claim the service is Tailnet-only without checking both the host firewall and upstream router/Cloudflare configuration.
- Do not expose `/etc/caddy/cloudflare.env`, Synapse signing keys, database credentials, access tokens, passwords or full secret-bearing configs.
- Keep full-disk encryption, non-root containers and `no-new-privileges` intact. Prefer read-only inspection when the request is an audit or explanation.
- Report backups, software updates and recovery testing separately from confidentiality controls: availability is part of the security posture.
