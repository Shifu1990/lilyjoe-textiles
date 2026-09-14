# ================================================================
# LilyJoe Textiles ERP - Railway Production Container
# PHP 8.2 + Apache with PDO MySQL & PostgreSQL (Supabase) Support
# ================================================================

FROM php:8.2-apache

# Install PostgreSQL client dev libraries and system utilities without recommended extras
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    bcmath \
    && rm -rf /var/lib/apt/lists/*

# Fix AH00534 (More than one MPM loaded):
# Ensure ONLY mpm_prefork is enabled, removing any conflicting mpm_event or mpm_worker symlinks
RUN rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf \
    && a2enmod mpm_prefork rewrite headers

# Configure PHP production directives
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'upload_max_filesize = 50M'; \
    echo 'post_max_size = 50M'; \
    echo 'max_execution_time = 120'; \
    echo 'date.timezone = Africa/Nairobi'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT'; \
} > /usr/local/etc/php/conf.d/production.ini

# Configure Apache VirtualHost with AllowOverride All
RUN { \
    echo '<VirtualHost *:80>'; \
    echo '    ServerAdmin webmaster@localhost'; \
    echo '    DocumentRoot /var/www/html'; \
    echo '    <Directory /var/www/html>'; \
    echo '        Options -Indexes +FollowSymLinks'; \
    echo '        AllowOverride All'; \
    echo '        Require all granted'; \
    echo '    </Directory>'; \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log'; \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined'; \
    echo '</VirtualHost>'; \
} > /etc/apache2/sites-available/000-default.conf

# Set working directory
WORKDIR /var/www/html

# Copy entrypoint script and fix line endings (handles Windows CRLF)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Copy application files
COPY . /var/www/html/

# Set correct ownership and permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Entrypoint guarantees single MPM and dynamic port binding on Railway container startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
