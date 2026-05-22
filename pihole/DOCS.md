# Pi-hole Add-on for Home Assistant

Network-wide ad blocking using Pi-hole v6 (FTL). Blocks ads, trackers, and malware domains for every device on your network — no per-device software needed.

The Pi-hole admin dashboard opens directly in the HA sidebar via the ingress panel.

## Prerequisites

Port **53** must be free on your Home Assistant host. If you're on a system using `systemd-resolved` (e.g. Ubuntu), disable it first:

```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

## Configuration

| Option | Default | Description |
|---|---|---|
| `upstream_dns` | `1.1.1.1;8.8.8.8` | Upstream DNS servers, semicolon-separated |
| `timezone` | `Europe/London` | IANA timezone string, e.g. `America/New_York` |
| `dnssec` | `false` | Enable DNSSEC validation |
| `listening_mode` | `all` | DNS listening mode: `all` \| `local` \| `single` \| `bind` |
| `blocking_enabled` | `true` | Enable ad/tracker blocking |
| `query_logging` | `true` | Log DNS queries (powers the dashboard statistics) |

### Example

```yaml
upstream_dns: "1.1.1.1;1.0.0.1"
timezone: "Europe/London"
dnssec: true
listening_mode: "all"
blocking_enabled: true
query_logging: true
```

## Pointing your network at Pi-hole

Set the **DNS server** on your router to your Home Assistant host IP (e.g. `192.168.1.x`). All devices using your router's DNS will go through Pi-hole automatically.

Alternatively, set it per-device in the device's network settings.

## Authentication

Pi-hole's own web authentication is disabled — access to the admin panel is controlled by Home Assistant's login. Anyone who can log into HA can access the Pi-hole dashboard; anyone who cannot cannot.

## Persistent storage

All Pi-hole data (gravity database, blocklists, custom DNS entries, query logs) is stored in the add-on's persistent data volume and survives restarts, updates, and HA reboots.
