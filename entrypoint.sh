#!/bin/sh
set -e

# Prevent Apache MPM conflict error (AH00534: More than one MPM loaded)
# Remove all enabled MPM modules and explicitly enable only mpm_prefork for PHP
rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf
a2enmod mpm_prefork rewrite headers > /dev/null 2>&1 || true

# Bind Apache to Railway dynamic $PORT (defaults to 80 if not set)
PORT="${PORT:-80}"
sed -i "s/Listen [0-9]*/Listen ${PORT}/g" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:[0-9]*>/<VirtualHost *:${PORT}>/g" /etc/apache2/sites-available/*.conf

# Execute command (defaults to apache2-foreground)
if [ $# -eq 0 ]; then
    exec apache2-foreground
else
    exec "$@"
fi
