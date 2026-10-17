#!/bin/bash
# One-time cleanup of the old web setup on the Linode, before running the
# Docker stack. Run as root:  task server-setup
set -euo pipefail

echo "== Removing stopped legacy containers and their images"
docker rm nginx tpms-frontend tpms-backend 2>/dev/null || true
docker rmi tpms_server_frontend:latest tpms_server_backend:latest \
    tpms_server-frontend:latest tpms_server-backend:latest \
    nginx:latest certbot/certbot:latest 2>/dev/null || true
docker image prune -f
docker network prune -f

echo "== Removing nginx and certbot (Caddy handles TLS now)"
systemctl disable --now certbot.timer 2>/dev/null || true
apt-get purge -y nginx-common certbot python3-certbot
apt-get purge -y $(dpkg -l | awk '/^rc/ && /nginx|ufw/ {print $2}') || true
apt-get autoremove --purge -y
rm -rf /etc/nginx /etc/letsencrypt /var/log/nginx /var/log/letsencrypt

echo "== Removing old web roots"
rm -f /var/www/html/index.nginx-debian.html /var/www/zmeiresearch/index.html \
    /var/www/wb.zmeiresearch.com/index.html
# rmdir only removes empty directories, so anything unexpected is left alone
rmdir /var/www/html /var/www/letsencrypt /var/www/zmeiresearch \
    /var/www/wb.zmeiresearch.com /var/www/loop.zmeiresearch.com \
    /var/www/arena-sys /var/www 2>/dev/null || true

echo "== Done. Ports 80/443 must be free:"
ss -tlnp | grep -E ':(80|443)\s' || echo "   (nothing listening on 80/443)"
