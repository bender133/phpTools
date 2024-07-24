#!/bin/bash

set -e

# Базовая директория
base_dir="/var/www"
report_dir="/var/www/php-quality-tools"
report_path_phpstan="$report_dir/phpstan_report.txt"
report_path_phpcs="$report_dir/phpcs_report.txt"

# Путь к инструментам
phpstan_path="/root/.composer/vendor/bin/phpstan"
phpcs_path="/root/.composer/vendor/bin/phpcs"
phpcbf_path="/root/.composer/vendor/bin/phpcbf"
phpcs_config="/var/www/php-quality-tools/phpcs.xml"   # Путь к конфигурационному файлу PHPCS
phpstan_config="/var/www/php-quality-tools/phpstan.neon.dist"   # Путь к конфигурационному файлу phpstan

# Дефолтные значения
default_level=1
default_scan_type=1  # 1 - сканировать все, 0 - сканировать только изменённые файлы

# Запрашиваем у пользователя тип анализа
echo "Выберите тип анализа:"
echo "1) PHPStan - проверка качества кода"
echo "2) PHP_CodeSniffer - проверка на соответствие PSR"
echo "3) PHP_CodeSniffer - проверка и исправление на соответствие PSR"
read -p "Введите номер выбранного типа анализа (по умолчанию: 1): " analysis_type
analysis_type=${analysis_type:-1}

# Запрашиваем у пользователя параметры для анализа
read -p "Введите относительный путь для сканирования (например, Libraries/moonwalk-client/src): " rel_scan_dir

# Дефолтные значения
default_scan_type=1  # 1 - сканировать все, 0 - сканировать только изменённые файлы

read -p "Сканировать всё (1) или только изменённые файлы (0) (по умолчанию: $default_scan_type): " scan_type
scan_type=${scan_type:-$default_scan_type}

# Проверка параметров
if [[ -z "$rel_scan_dir" || -z "$scan_type" ]]; then
    echo "Все параметры обязательны для заполнения."
    exit 1
fi

# Полные пути
scan_dir="$base_dir/$rel_scan_dir"

if [[ "$scan_type" == "0" ]]; then
    # Запрашиваем путь к репозиторию Git только если нужно сканировать изменённые файлы
    read -p "Введите относительный путь к репозиторию Git (например, Libraries/moonwalk-client): " rel_git_dir

    if [[ -z "$rel_git_dir" ]]; then
        echo "Путь к репозиторию Git обязателен для выбора сканирования изменённых файлов."
        exit 1
    fi

    git_dir="$base_dir/$rel_git_dir"

    # Получаем список изменённых файлов
    changed_files=$(cd "$git_dir" && git diff --name-only --diff-filter=ACMRTUXB HEAD~1 | grep "\.php$")
    if [[ -z "$changed_files" ]]; then
        echo "Нет изменённых PHP файлов для анализа."
        exit 1
    fi

    # Преобразуем список файлов в абсолютные пути и разделённые пробелами
    changed_files=$(echo "$changed_files" | sed "s|^|$git_dir/|" | tr '\n' ' ' | sed 's/ *$//')

    # Формируем команду для сканирования
    scan_target=($changed_files)
else
    # Формируем команду для сканирования всех файлов
    scan_target=("$scan_dir")
fi

# Формируем команду в зависимости от выбранного типа анализа
case $analysis_type in
    1)
        # PHPStan
        report_dir=$report_path_phpstan
        cmd=("$phpstan_path" "analyse" "${scan_target[@]}" "--configuration=$phpstan_config" "--error-format=table")
        ;;
    2)
        # PHP_CodeSniffer - проверка на соответствие PSR
        report_dir=$report_path_phpcs
        cmd=("$phpcs_path" "--standard=$phpcs_config" "${scan_target[@]}")
        ;;
    3)
        # PHP_CodeSniffer - проверка и исправление на соответствие PSR
        report_dir=$report_path_phpcs
        cmd=("$phpcbf_path" "--standard=$phpcs_config" "${scan_target[@]}")
        ;;
    *)
        echo "Неверный выбор типа анализа."
        exit 1
        ;;
esac

# Вывод команды для отладки
echo "Команда для выполнения: ${cmd[@]}"

# Выполняем команду и сохраняем отчет
"${cmd[@]}" > "$report_dir"

echo "Анализ завершён. Отчет сохранён в $report_dir."
