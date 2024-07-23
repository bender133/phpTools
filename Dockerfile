FROM php:7.4-fpm

# Установить системные зависимости
RUN apt-get update && apt-get install -y git dos2unix

# Настроить глобальную конфигурацию Git
RUN git config --global core.autocrlf input

# Получить последнюю версию Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Установка необходимых системных зависимостей
RUN apt-get update && apt-get install -y \
        unzip \
        libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Установка расширения zip для PHP
RUN docker-php-ext-install zip

# Установка PHPStan и PHP_CodeSniffer
RUN composer global require phpstan/phpstan \
    && composer global require squizlabs/php_codesniffer

# Создание рабочей директории
WORKDIR /var/www

# Настройка алиасов
RUN echo "alias phpstan='php /root/.composer/vendor/bin/phpstan'" >> ~/.bashrc \
    && echo "alias phpcs='php /root/.composer/vendor/bin/phpcs'" >> ~/.bashrc \
    && echo "alias phpcbf='php /root/.composer/vendor/bin/phpcbf'" >> ~/.bashrc

# Копирование скриптов и установка разрешений
COPY phpstan_analysis.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/phpstan_analysis.sh

# Загрузка входной точки
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["php-fpm"]
