#!/bin/sh
# VERSION=4.2
# SSL certificate via acme.sh and the Hetzner Cloud DNS API
# (dnsapi plugin: dns_hetznercloud, token variable: HETZNER_TOKEN)
# Target: Teltonika RutOS / OpenWrt (BusyBox ash)

# load configuration (seeded by /etc/rc.local on first boot)
[ -f /root/ssl.conf ] && . /root/ssl.conf

DOMAIN="${SSL_DOMAIN:-}"
MAIL="${ACME_MAIL:-}"
export HETZNER_TOKEN="${HETZNER_TOKEN:-}"

# where uhttpd expects its certificate (RutOS default paths - check with
# "uci get uhttpd.main.cert"; plain OpenWrt uses /etc/uhttpd.crt|key)
CERT_FILE="${SSL_CERT_FILE:-/etc/certificates/uhttpd.crt}"
KEY_FILE="${SSL_KEY_FILE:-/etc/certificates/uhttpd.key}"
RELOAD_CMD="${SSL_RELOAD_CMD:-/etc/init.d/uhttpd restart}"

ACME=/root/.acme.sh/acme.sh

log() {
  echo "${1}: ${DOMAIN}: ${2}"
  logger -t ssl "${1}: ${DOMAIN}: ${2}"
}

if [ -z "$DOMAIN" ] || [ -z "$MAIL" ] || [ -z "$HETZNER_TOKEN" ] \
   || [ "$HETZNER_TOKEN" = "YOUR_HETZNER_CLOUD_API_TOKEN" ]; then
  log Error "SSL_DOMAIN, ACME_MAIL or HETZNER_TOKEN missing. Edit /root/ssl.conf."
  exit 1
fi

# wait for the WAN to come up (this runs right after boot) - up to 60 s
i=0
while [ $i -lt 12 ]; do
  curl -s --connect-timeout 5 https://acme-v02.api.letsencrypt.org/directory >/dev/null 2>&1 && break
  i=$((i+1))
  sleep 5
done

# install the acme.sh client on first run
if [ ! -f "$ACME" ]; then
  log Info "Installing acme.sh client."
  curl -s https://get.acme.sh | sh -s email="$MAIL"
fi

if [ ! -f "$ACME" ]; then
  log Error "acme.sh installation failed."
  exit 1
fi

# find the stored domain configuration (ecc is the acme.sh default)
domain_conf=""
domain_dir=""
ecc_flag=""
for d in "/root/.acme.sh/${DOMAIN}_ecc" "/root/.acme.sh/${DOMAIN}"; do
  if [ -f "${d}/${DOMAIN}.conf" ]; then
    domain_conf="${d}/${DOMAIN}.conf"
    domain_dir="$d"
    case "$d" in *_ecc) ecc_flag="--ecc";; esac
    break
  fi
done

# copy the certificate to the uhttpd paths when missing or outdated;
# also stores the install paths for future automatic renewals
ensure_installed() {
  acme_cert="${domain_dir}/fullchain.cer"
  [ -f "$acme_cert" ] || return 0
  if [ -f "$CERT_FILE" ] \
     && [ "$(md5sum < "$acme_cert")" = "$(md5sum < "$CERT_FILE")" ]; then
    return 0
  fi
  log Info "Installing certificate to ${CERT_FILE}."
  if "$ACME" --install-cert -d "$DOMAIN" $ecc_flag \
       --fullchain-file "$CERT_FILE" --key-file "$KEY_FILE" \
       --reloadcmd "$RELOAD_CMD"; then
    log Info "Certificate installed and webserver reloaded."
  else
    log Error "Certificate install failed - see /root/.acme.sh/acme.sh.log"
    return 1
  fi
}

if [ -z "$domain_conf" ]; then
  # first run - issue a new certificate
  log Info "Issuing new certificate."
  if "$ACME" --issue --dns dns_hetznercloud --server letsencrypt -d "$DOMAIN" \
       --fullchain-file "$CERT_FILE" --key-file "$KEY_FILE" \
       --reloadcmd "$RELOAD_CMD" --log; then
    log Info "Certificate issued and installed successfully."
  else
    log Error "Certificate issue failed - see /root/.acme.sh/acme.sh.log"
    exit 1
  fi
elif ! grep -q 'dns_hetznercloud' "$domain_conf"; then
  # cert was issued with the retired dns_hetzner plugin - reissue once
  log Info "Migrating to the dns_hetznercloud plugin - reissuing certificate."
  if "$ACME" --issue --force --dns dns_hetznercloud --server letsencrypt -d "$DOMAIN" \
       --fullchain-file "$CERT_FILE" --key-file "$KEY_FILE" \
       --reloadcmd "$RELOAD_CMD" --log; then
    log Info "Certificate reissued and installed successfully."
  else
    log Error "Certificate reissue failed - see /root/.acme.sh/acme.sh.log"
    exit 1
  fi
else
  # renew skips automatically while the certificate is still valid
  # (exit code 2 = not yet due, that is fine)
  "$ACME" --renew -d "$DOMAIN" --server letsencrypt --log
  ret=$?
  if [ "$ret" = "0" ]; then
    log Info "Certificate renewed successfully."
  elif [ "$ret" != "2" ]; then
    log Error "Certificate renewal failed (rc=${ret}) - see /root/.acme.sh/acme.sh.log"
    exit 1
  fi
  ensure_installed
fi
