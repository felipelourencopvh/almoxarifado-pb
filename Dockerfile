# Dockerfile – versão final e garantida (PHP 8.4 + Alpine)
FROM php:8.4-fpm-alpine

# Argumentos do usuário/grupo
ARG UID=1000
ARG GID=1000
ARG USER=sail
ARG GROUP=sail

# Instala tudo de uma vez (incluindo as deps temporárias que o pecl precisa)
RUN apk add --no-cache \
        git \
        curl \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        zip \
        unzip \
        oniguruma-dev \
        libxml2-dev \
        postgresql-dev \
        autoconf \
        g++ \
        make \
        linux-headers \
        # deps temporárias que o pecl exige (vamos remover depois)
        php84-pecl-redis \
        php84-pecl-xdebug \
        php84-pecl-pcov \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_pgsql pgsql bcmath \
    && pecl install redis pcov xdebug \
    && docker-php-ext-enable redis pcov xdebug \
    # Remove tudo que foi usado só pra compilar (imagem fica ~170 MB)
    && apk del autoconf g++ make linux-headers php84-pecl-* \
    && rm -rf /tmp/pear

# Cria usuário sail (igual o Laravel Sail oficial)
RUN addgroup -g ${GID} ${GROUP} \
    && adduser -D -u ${UID} -G ${GROUP} -s /bin/sh ${USER}

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Código da aplicação
WORKDIR /var/www/html
COPY --chown=${USER}:${GROUP} . /var/www/html

# Permissões
RUN chmod -R 755 storage bootstrap/cache

# Usuário não-root
USER ${USER}

CMD ["php-fpm"]
