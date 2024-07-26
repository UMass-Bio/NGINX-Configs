#!/bin/sh

# Copyright (C) 2024 Thien Tran
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

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

# Add 99-nonlocal-bind.conf
# This fixes a long standing bug where network-online.target is reached before IPv6 is obtained, which breaks IPv6 pinning.
# Also, if you are using floating IPs for NGINX stream like I do, you need it anyways
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/sysctl.d/99-nonlocal-bind.conf | sudo tee /etc/sysctl.d/99-nonlocal-bind.conf
sudo chmod 644 /etc/sysctl.d/99-nonlocal-bind.conf

# Setup webroot for NGINX
## Explicitly using /var/srv here because SELinux does not follow symlinks
sudo semanage fcontext -a -t httpd_sys_content_t "/var/srv/nginx(/.*)?"
sudo mkdir -p /srv/nginx/.well-known/acme-challenge
sudo chmod -R 755 /srv/nginx/.well-known/acme-challenge

# NGINX hardening
sudo mkdir -p /etc/systemd/system/nginx.service.d
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx.service.d/local.conf | sudo tee /etc/systemd/system/nginx.service.d/override.conf
chmod 644 /etc/systemd/system/nginx.service.d/override.conf
sudo systemctl daemon-reload

# Setup nginx-create-session-ticket-keys
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/nginx-create-session-ticket-keys | sudo tee /usr/local/bin/nginx-create-session-ticket-keys
## Explicitly using /var/usrlocal/bin here because SELinux does not follow symlinks
sudo semanage fcontext -a -t bin_t /var/usrlocal/bin/nginx-create-session-ticket-keys
sudo restorecon /var/usrlocal/bin/nginx-create-session-ticket-keys
sudo chmod u+x /var/usrlocal/bin/nginx-create-session-ticket-keys
echo 'restorecon -Rv /etc/nginx/session-ticket-keys' | sudo tee -a /usr/local/bin/nginx-create-session-ticket-keys

# Setup nginx-rotate-session-ticket-keys
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/nginx-rotate-session-ticket-keys | sudo tee /usr/local/bin/nginx-rotate-session-ticket-keys
## Explicitly using /var/usrlocal/bin here because SELinux does not follow symlinks
sudo semanage fcontext -a -t bin_t /var/usrlocal/bin/nginx-rotate-session-ticket-keys
sudo restorecon -Rv /var/usrlocal/bin/nginx-rotate-session-ticket-keys
sudo chmod u+x /var/usrlocal/bin/nginx-rotate-session-ticket-keys
sudo sed -i '$i restorecon -Rv /etc/nginx/session-ticket-keys' /var/usrlocal/bin/nginx-rotate-session-ticket-keys

# Download the units
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/certbot-ocsp-fetcher.service | sudo tee /etc/systemd/system/certbot-ocsp-fetcher.service
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/certbot-ocsp-fetcher.timer | sudo tee /etc/systemd/system/certbot-ocsp-fetcher.timer
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx-create-session-ticket-keys.service | sudo tee /etc/systemd/system/nginx-create-session-ticket-keys.service
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx-rotate-session-ticket-keys.service | sudo tee /etc/systemd/system/nginx-rotate-session-ticket-keys.service
unpriv curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/nginx-rotate-session-ticket-keys.timer | sudo tee /etc/systemd/system/nginx-rotate-session-ticket-keys.timer

# Systemd Hardening
sudo mkdir -p /etc/systemd/system/nginx.service.d /etc/systemd/system/certbot-renew.service.d
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/systemd/system/nginx.service.d/override.conf | sudo tee /etc/systemd/system/nginx.service.d/override.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/systemd/system/certbot-renew.service.d/override.conf | sudo tee /etc/systemd/system/certbot-renew.service.d/override.conf
sudo systemctl daemon-reload

# Enable the units
sudo systemctl enable certbot-ocsp-fetcher.timer
sudo systemctl enable --now nginx-create-session-ticket-keys.service
sudo systemctl enable --now nginx-rotate-session-ticket-keys.timer

# Download NGINX configs

unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/conf.d/http2.conf | sudo tee /etc/nginx/conf.d/http2.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/conf.d/sites_default.conf | sudo tee /etc/nginx/conf.d/sites_default.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/conf.d/tls.conf | sudo tee /etc/nginx/conf.d/tls.conf

sudo mkdir -p /etc/nginx/snippets
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/snippets/hsts.conf | sudo tee /etc/nginx/snippets/hsts.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/snippets/proxy.conf | sudo tee /etc/nginx/snippets/proxy.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/snippets/quic.conf | sudo tee /etc/nginx/snippets/quic.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/snippets/security.conf | sudo tee /etc/nginx/snippets/security.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/snippets/cross-origin-security.conf | sudo tee /etc/nginx/snippets/cross-origin-security.conf
unpriv curl https://raw.githubusercontent.com/TommyTran732/NGINX-Configs/main/etc/nginx/snippets/universal_paths.conf | sudo tee /etc/nginx/snippets/universal_paths.conf
