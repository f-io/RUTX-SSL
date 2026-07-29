# Teltonika RUTX SSL

Valid Let's Encrypt certificates on Teltonika RUTX (RutOS / OpenWrt) devices
via [acme.sh](https://github.com/acmesh-official/acme.sh) with a DNS-01
challenge against the **Hetzner Cloud DNS API** (`dns_hetznercloud` plugin).

## Installation

1. Copy the content of [rc.local](rc.local) into **System → Custom Scripts**
   in the WebUI (`/etc/rc.local`).
2. Fill in the configuration block at the top:
   - `HETZNER_TOKEN` - Hetzner **Cloud** API token (project token with
     read & write permissions, created in the Hetzner Cloud Console)
   - `SSL_DOMAIN` - the certificate domain, e.g. `router.example.com`
   - `ACME_MAIL` - your account mail address
3. Reboot.

To change the configuration later, edit `/root/ssl.conf` on the device -
the block in `rc.local` is only used to seed it once.

## Related

- [RUTX-DYNDNS-HETZNER](https://github.com/f-io/RUTX-DYNDNS-HETZNER) -
  DynDNS (A + AAAA) via the Hetzner Cloud DNS API
- [RUTX-GPS](https://github.com/f-io/RUTX-GPS) - GPS tracking to Nextcloud
  PhoneTrack
- [Combined rc.local example](https://github.com/f-io/RUTX-DYNDNS-HETZNER/blob/main/examples/rc.local.combined)
  (DynDNS + SSL + GPS)

## Tested Devices

| Device  | Firmware Version          |
|---------|---------------------------|
| RUTX11  | RUTX_R_00.07.24.1         |
| RUTX11  | RUTX_R_00.07.12           |
| RUTX50  | RUTX_R_00.07.06.3         |


## Changelog

- **2026-07-29** - Switched to the Hetzner **Cloud** DNS API
  (`dns_hetznercloud`), automatic migration/reissue for certificates from
  the retired `dns_hetzner` plugin, script is now downloaded from this repo,
  configuration moved to `/root/ssl.conf`.
- **Check for acme client before download**.
