# Pi-hole — Home Assistant Add-on

Network-wide ad blocking via your own DNS server. Blocks ads, trackers, and malware domains for **every device on your network** — no per-device software needed.

Runs **Pi-hole v6** (FTL built-in web server) with full support for the Pi-hole admin dashboard embedded in the HA sidebar.

## Features

- Pi-hole **v6 / FTL** — not the legacy v5 that most other HA addons use
- **Sidebar panel** — full admin dashboard embedded in HA via ingress proxy
- Persistent storage — blocklists, gravity DB, and query logs survive restarts/updates
- Configurable upstream DNS, DNSSEC, listening mode, and query logging
- DNS on host port 53 (TCP + UDP)
- No separate Pi-hole password needed — access is controlled by HA login

## Installation

1. In Home Assistant go to **Settings → Add-ons → Add-on Store**.
2. Click **⋮ → Repositories** and add:
   ```
   https://github.com/chrisleech/ha-addon-pihole
   ```
3. Find **Pi-hole** in the store and click **Install**.
4. Configure options (upstream DNS, timezone, etc.) then click **Start**.
5. The **Pi-hole** entry appears in the HA sidebar automatically.

## Prerequisites

Port **53** must be free on your HA host. On Ubuntu/Debian with `systemd-resolved`:

```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

## Configuration

| Option | Default | Description |
|---|---|---|
| `upstream_dns` | `1.1.1.1;8.8.8.8` | Upstream DNS servers (semicolon-separated) |
| `timezone` | `Europe/London` | IANA timezone, e.g. `America/New_York` |
| `dnssec` | `false` | Enable DNSSEC validation |
| `listening_mode` | `all` | `all` \| `local` \| `single` \| `bind` |
| `blocking_enabled` | `true` | Enable ad/tracker blocking |
| `query_logging` | `true` | Log DNS queries for dashboard statistics |

## Pointing your network at Pi-hole

Set the DNS server on your router to your **HA host IP**. All devices that use your router's DNS will go through Pi-hole automatically.

## Changelog

### 6.0.3
- Fix: all admin sub-pages (Settings, Queries, Groups, etc.) now render correctly in the HA ingress panel
- Inject `<base>` tag so relative asset paths resolve correctly from any page depth

### 6.0.2
- Fix: increased nginx proxy buffer size so `sub_filter` works reliably on large Pi-hole HTML responses

### 6.0.1
- Fix: nginx `sub_filter` rewrites absolute `/admin/` paths to ingress-relative paths

### 6.0.0
- Initial release — Pi-hole v6 (FTL), HA ingress sidebar panel, persistent storage
