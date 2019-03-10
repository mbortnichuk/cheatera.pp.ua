FROM php:7.2-apache

WORKDIR /var/www/html

# Install required packages and PHP modules
RUN apt-get update 
RUN apt-get upgrade -y
RUN apt-get -y install --fix-missing apt-utils build-essential git curl libcurl3 libcurl3-dev zip \
    libmcrypt-dev libsqlite3-dev libsqlite3-0 mysql-client zlib1g-dev libicu-dev sendmail libfreetype6-dev \
    libjpeg62-turbo-dev libpng-dev wget net-tools

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP7 Extensions
RUN docker-php-ext-install pdo_mysql pdo_sqlite mysqli curl tokenizer json zip mbstring
RUN docker-php-ext-install -j$(nproc) intl
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ 
RUN docker-php-ext-install -j$(nproc) gd

# Install phpunit
RUN wget https://phar.phpunit.de/phpunit-6.0.phar \
    && chmod +x phpunit-6.0.phar \
    && mv phpunit-6.0.phar /usr/local/bin/phpunit

# Install codecept
RUN wget http://codeception.com/codecept.phar \
    && chmod +x codecept.phar \
    && mv codecept.phar /usr/local/bin/codecept

# Update apache2.conf
RUN a2enmod rewrite
RUN sed -i 's#DocumentRoot /var/www/html#DocumentRoot /var/www/html/web#' /etc/apache2/apache2.conf

# Fix write permissions with shared folders
RUN usermod -u 1000 www-data

# We first install any composer packages outside of the web root to prevent them
# from being overwritten by the COPY below. If the composer.lock file here didn't
# change, docker will use the cached composer files.
COPY composer.json /var/www/html/
COPY composer.lock /var/www/html/
RUN composer self-update
RUN composer install

# Copy the working dir to the image's web root
COPY . /var/www/html
RUN mkdir -p /var/www/html/web/assets

# Setup xdebug
RUN yes | pecl install xdebug
# Copy php.ini into image
COPY php.ini.example /usr/local/etc/php/php.ini
RUN echo "\nzend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" >> /usr/local/etc/php/php.ini
RUN echo 'memory_limit=512M' >> /usr/local/etc/php/php.ini
