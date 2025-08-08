# NGINX Configs

[![ShellCheck](https://github.com/UMass-Bio/NGINX-Configs/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/UMass-Bio/NGINX-Configs/actions/workflows/shellcheck.yml)

These are my NGINX configurations. They are written for mainline NGINX on RHEL.

## Getting Started

1. Install `nginx` from the mainline repository, `certbot`, and `python3-certbot-nginx`. Makesure rsync is available on the OS.
2. Run `setup.sh`
3. Generate a certificate with your hostname. Copy `etc/nginx/conf.d/sites_default_quic.conf` to the corresponding directory on your server and edit it approprieately.

## Certificate Issuance 

```bash
#!/bin/sh

certbot certonly \
    --webroot --webroot-path /srv/nginx \
    --no-eff-email \
    --key-type ecdsa \
    --reuse-key \
    --deploy-hook "nginx -s reload" \
    -d hostname.of.your.server
```