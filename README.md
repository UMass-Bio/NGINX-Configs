# NGINX Configs

These are my NGINX configurations. They are written for Fedora CoreOS's NGINX build with `nginx-mod-stream`.

## Getting Started

1. Install `nginx`, `nginx-mod-stream`, and `policycoreutils-python-utils` on Fedora. Makesure `rsync` is available on the OS.
2. Comment out the default server block in `/etc/nginx/nginx.conf`.
3. Copy all configuration files in `/etc/nginx` except the ones named `/etc/nginx/conf.d/sites_.*` to the corresponding location onto the server.
4. Run `setup.sh`
5. Make a dummy vhost listening on port `80` with the server_name you want.
6. Generate certificates with the example in the certbot directory.
7. Copy `/etc/nginx/conf.d/sites_default.conf` to `/etc/nginx/conf.d` for https redirection.
8. Make your actual vhost config based on the `sites_.*` samples in `/etc/nginx/conf.d/sites_default.conf`.

## Notes

This is used on my tunnel servers with multiple IP addresses. Hence, you may see addresses like `ipv4_1` and `ipv4_2`. Just replace them with your own ip addresses.
