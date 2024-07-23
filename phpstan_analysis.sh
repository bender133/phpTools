#!/bin/bash

set -e

# Базовая директория
base_dir="/var/www"
report_dir="/var/www/php-tools"
report_path="$report_dir/php-tools_report.txt"

# Путь к инструментам
phpstan_path="/root/.composer/vendor/bin/phpstan"
phpcs_path="/root/.composer/vendor/bin/phpcs"
phpcbf_path="/root/.composer/vendor/bin/phpcbf"
phpcs_config="/var/www/php-tools/phpcs.xml"   # Путь к конфигурационному файлу PHPCS

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

if [[ "$analysis_type" == "1" ]]; then
    # Запрашиваем уровень проверки только если выбран PHPStan
    read -p "Введите уровень проверки (0-9, по умолчанию: $default_level): " level
    level=${level:-$default_level}
else
    # Устанавливаем уровень проверки по умолчанию для других инструментов
    level=""
fi

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
    changed_files=$(echo "$changed_files" | sed "s|^|$git_dir/|" | tr '\n' ' ')

    # Формируем команду для сканирования
    scan_target="$changed_files"
else
    # Формируем команду для сканирования всех файлов
    scan_target="$scan_dir"
fi

# Формируем команду в зависимости от выбранного типа анализа
case $analysis_type in
    1)
        # PHPStan
        cmd="$phpstan_path analyse \"$scan_target\" --level=$level --error-format=table"
        ;;
    2)
        # PHP_CodeSniffer - проверка на соответствие PSR
        cmd="$phpcs_path --standard=PSR12 --ignore-annotations \"$scan_target\""
        ;;
    3)
        # PHP_CodeSniffer - проверка и исправление на соответствие PSR
        cmd="$phpcbf_path --standard=PSR12 --ignore-annotations \"$scan_target\""
        ;;
    *)
        echo "Неверный выбор типа анализа."
        exit 1
        ;;
esac

# Вывод команды для отладки
echo "Команда для выполнения: $cmd > $report_path"

# Выполняем команду и сохраняем отчет
echo "Отчет будет сохранён в: $report_path"
eval "$cmd > $report_path"

echo "Анализ завершён. Отчет сохранён в $report_path."
