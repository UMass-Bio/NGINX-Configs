#!/bin/sh

set -eu

output(){
    printf '\e[1;34m%-6s\e[m\n' "${@}"
}

unpriv(){
    sudo -u nobody "$@"
}

# Allow reverse proxy
sudo setsebool -P httpd_can_network_connect 1

# Allow QUIC
sudo semanage port -a -t http_port_t -p udp 443

# Open ports for NGINX
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=443/udp
sudo firewall-cmd --reload

# Setup webroot for NGINX
## Explicitly using /var/srv here because SELinux does not follow symlinks
sudo semanage fcontext -a -t httpd_sys_content_t "$(realpath /srv/nginx)(/.*)?"
sudo mkdir -p /srv/nginx/.well-known/acme-challenge
sudo chmod -R 755 /srv/nginx/.well-known/acme-challenge

# NGINX hardening
sudo mkdir -p /etc/systemd/system/nginx.service.d
unpriv curl -s https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx.service.d/local.conf | sudo tee /etc/systemd/system/nginx.service.d/override.conf > /dev/null
sudo chmod 644 /etc/systemd/system/nginx.service.d/override.conf
sudo systemctl daemon-reload

# Setup nginx-create-session-ticket-keys
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/scripts/nginx-create-session-ticket-keys-ramfs | sudo tee /usr/local/bin/nginx-create-session-ticket-keys > /dev/null

## Set the appropriate SELinux context for session ticket keys creation
sudo semanage fcontext -a -t bin_t "$(realpath /usr/local/bin/nginx-create-session-ticket-keys)"
sudo restorecon "$(realpath /usr/local/bin/nginx-create-session-ticket-keys)"
sudo chmod u+x "$(realpath /usr/local/bin/nginx-create-session-ticket-keys)"
echo 'restorecon -Rv /etc/nginx/session-ticket-keys' | sudo tee -a "$(realpath /usr/local/bin/nginx-create-session-ticket-keys)"

# Set the appropriate SELinux context for session ticket keys rotation
unpriv curl -s https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/nginx-rotate-session-ticket-keys | sudo tee /usr/local/bin/nginx-rotate-session-ticket-keys > /dev/null
## Explicitly using /var/usrlocal/bin here because SELinux does not follow symlinks
sudo semanage fcontext -a -t bin_t "$(realpath /usr/local/bin/nginx-rotate-session-ticket-keys)"
sudo restorecon -Rv "$(realpath /usr/local/bin/nginx-rotate-session-ticket-keys)"
sudo chmod u+x "$(realpath /usr/local/bin/nginx-rotate-session-ticket-keys)"
sudo sed -i '$i restorecon -Rv /etc/nginx/session-ticket-keys' "$(realpath /usr/local/bin/nginx-rotate-session-ticket-keys)"

# Download the units
unpriv curl -s https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx-create-session-ticket-keys.service | sudo tee /etc/systemd/system/nginx-create-session-ticket-keys.service > /dev/null
unpriv curl -s https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx-rotate-session-ticket-keys.service | sudo tee /etc/systemd/system/nginx-rotate-session-ticket-keys.service > /dev/null
unpriv curl -s https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx-rotate-session-ticket-keys.timer | sudo tee /etc/systemd/system/nginx-rotate-session-ticket-keys.timer > /dev/null

# Systemd Hardening
sudo mkdir -p /etc/systemd/system/nginx.service.d /etc/systemd/system/certbot-renew.service.d
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/systemd/system/nginx.service.d/override.conf | sudo tee /etc/systemd/system/nginx.service.d/override.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/systemd/system/certbot-renew.service.d/override.conf | sudo tee /etc/systemd/system/certbot-renew.service.d/override.conf > /dev/null
sudo systemctl daemon-reload

# Enable the units
sudo systemctl enable --now nginx-create-session-ticket-keys.service
sudo systemctl enable --now nginx-rotate-session-ticket-keys.timer

# Download NGINX configs

unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/conf.d/http2.conf | sudo tee /etc/nginx/conf.d/http2.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/conf.d/sites_default.conf | sudo tee /etc/nginx/conf.d/sites_default.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/conf.d/tls.conf | sudo tee /etc/nginx/conf.d/tls.conf > /dev/null

sudo mkdir -p /etc/nginx/snippets
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/snippets/hsts.conf | sudo tee /etc/nginx/snippets/hsts.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/snippets/proxy.conf | sudo tee /etc/nginx/snippets/proxy.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/snippets/quic.conf | sudo tee /etc/nginx/snippets/quic.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/snippets/security.conf | sudo tee /etc/nginx/snippets/security.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/snippets/cross-origin-security.conf | sudo tee /etc/nginx/snippets/cross-origin-security.conf > /dev/null
unpriv curl -s https://raw.githubusercontent.com/UMass-Bio/NGINX-Configs/main/etc/nginx/snippets/universal_paths.conf | sudo tee /etc/nginx/snippets/universal_paths.conf > /dev/null