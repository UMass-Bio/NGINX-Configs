# NGINX Configs

[![ShellCheck](https://github.com/TommyTran732/NGINX-Configs/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/TommyTran732/Linux-Setup-Scripts/actions/workflows/shellcheck.yml)

These are my NGINX configurations. They are written for Fedora CoreOS's NGINX build with `nginx-mod-stream`.

## Getting Started

1. Install `nginx`, `nginx-mod-stream`, and `policycoreutils-python-utils` on Fedora. Makesure `rsync` is available on the OS.
2. Comment out the default server block in `/etc/nginx/nginx.conf`.
3. Run `setup.sh`
4. Make a dummy vhost listening on port `80` with the server_name you want.
5. Generate certificates with the example in the certbot directory.
6. Make your actual vhost config based on the `sites_.*` samples in `/etc/nginx/conf.d`.

## Notes

This is used on my tunnel servers with multiple IP addresses. Hence, you may see addresses like `ipv4_1` and `ipv4_2`. Just replace them with your own ip addresses.
