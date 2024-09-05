# NGINX Configs

[![ShellCheck](https://github.com/UMass-Bio/NGINX-Configs/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/UMass-Bio/NGINX-Configs/actions/workflows/shellcheck.yml)

These are my NGINX configurations. They are written for mainline NGINX on RHEL.

## Getting Started

1. Install `nginx` from the mainline repository, `certbot`, and `python3-certbot-nginx`. Makesure rsync is available on the OS.Makesure `rsync` is available on the OS.
2. Move `/etc/nginx/conf.d/default.conf` to `/etc/nginx/conf.d/default.conf.bk`
3. Run `setup.sh`
4. Generate a certificate with your hostname with the `certbot/default-quic` example. Copy `etc/nginx/conf.d/sites_default_quic.conf` to the corresponding directory on your server and edit it approprieately.
5. Generate certificates with the example in the certbot directory.
6. Make your actual vhost config based on the `sites_.*` samples in `/etc/nginx/conf.d`.
