# ================================================================
# LilyJoe Textiles ERP - Railway Production Container
# PHP 8.2 + Apache with PDO MySQL & PostgreSQL (Supabase) Support
# ================================================================

FROM php:8.2-apache

# Install PostgreSQL client dev libraries and system utilities
RUN apt-get update && apt-get install -y \
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

# Enable Apache rewrite and headers modules
RUN a2enmod rewrite headers

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

# Copy application files
COPY . /var/www/html/

# Set correct ownership and permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Dynamic port binding for Railway ($PORT environment variable)
CMD sh -c "sed -i 's/80/'\"\${PORT:-80}\"'/g' /etc/apache2/ports.conf /etc/apache2/sites-available/*.conf && exec apache2-foreground"
