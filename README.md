# Teltonika RUTX SSL
Script to use ACME.sh on Teltonika (OpenWRT) devices to get valid ssl certificates for example with ZeroSSL or Letsencrypt.<br>

## Installation

Place this script in **Custom Scripts** within the Teltonika GUI (`/etc/rc.local`).

## Tested Devices

| Device  | Firmware Version          |
|---------|---------------------------|
| RUTX50  | RUTX_R_00.07.06.3         |
| RUTX11  | RUTX_R_00.07.12           |

## Changelog

- **Check for acme client befor download**.