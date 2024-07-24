# **Анализ кода через phpstan и CodeSniffer**

1. **Сборка контейнера:**

    ```bash
    docker-compose up -d --build
    ```

2. Создать в корне файлы `phpcs.xml` и `phpstan.neon.dist`, скопировать в них содержимое [phpcs.xml.example](phpcs.xml.example) и [phpstan.neon.dist.example](phpstan.neon.dist.example), при необходимости добавив нужные параметры.

3. **Запуск скрипта:**

    ```bash
    docker-compose exec app bash -c "/var/www/php-quality-tools/script.sh"
    ```

   Запускать команду нужно в директории `php-quality-tools` и следовать шагам скрипта.

4. **Результаты:**
    - phpstan - `phpstan_report.txt`
    - CodeSniffer - `phpcs_report.txt`

**`/var/www/` находится на уровень выше текущей директории.**

**Рекомендуемая структура проекта:**
- `poker` (общая папка с проектами, `/var/www/` внутри контейнера)
    - `php-quality-tools`
    - `api`
    - `other`

**Соответственно, если нужно просканировать API, то:**
- абсолютный путь до `src` внутри контейнера будет `/var/www/api/src`
- относительный путь до `src` внутри контейнера будет `api/src`
- относительный путь до git-репозитория будет `api/`

Главное, чтобы эта папка была на уровне или выше папок других проектов.
