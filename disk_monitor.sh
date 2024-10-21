#!/bin/bash

# Объявляем переменные
SCRIPT_DIR=$(dirname "$(realpath "$0")")
PID_FILE="$SCRIPT_DIR/disk_monitor.pid"
LOG_DIR="$SCRIPT_DIR/disk_monitor"
INTERVAL=60

# Создаем CSV
get_csv_filename() {
    echo "${LOG_DIR}/disk_usage_$(date +"%Y-%m-%d").csv"
}

# Функция мониторинга
monitor_disk() {
    local csv_file=$(get_csv_filename)

    # Создаем header файла
    if [ ! -f "$csv_file" ]; then
        echo "Timestamp,Disk_Use%,Inodes_Free" > "$csv_file"
    fi

    while true; do
        # Проверяем не перешли ли мы на следующий день
        local current_file=$(get_csv_filename)
        if [ "$current_file" != "$csv_file" ]; then
            csv_file=$current_file
            echo "Timestamp,Disk_Use%,Inodes_Free" > "$csv_file"
        fi

        # Получаем данные
        local disk_data=$(df -h / | awk 'NR==2 {print $5}')
        local inode_data=$(df -i / | awk 'NR==2 {print $4}')

        # Добавляем в конец
        echo "$(date +"%Y-%m-%d %H:%M:%S"),${disk_data},${inode_data}" >> "$csv_file"

        sleep $INTERVAL
    done
}

# Функция запуска мониторинга
start_monitoring() {
    if [ -f "$PID_FILE" ]; then
        echo "Мониторинг уже запущен с PID $(cat $PID_FILE)"
        exit 1
    fi

    mkdir -p "$LOG_DIR"
    monitor_disk &
    echo $! > "$PID_FILE"
    echo "Запускам мониторинг с PID $(cat $PID_FILE)"
}

# Функция остановки мониторинга
stop_monitoring() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Мониторинг не запущен"
        exit 1
    fi

    kill $(cat "$PID_FILE")
    rm "$PID_FILE"
    echo "Мониторинг остановлен"
}

# Функция проверки статуса мониторинга
check_status() {
    if [ -f "$PID_FILE" ]; then
        echo "Мониторинг запущен с PID $(cat $PID_FILE)"
    else
        echo "Мониторинг не запущен"
    fi
}

# Главная часть
case "$1" in
    START)
        start_monitoring
        ;;
    STOP)
        stop_monitoring
        ;;
    STATUS)
        check_status
        ;;
    *)
        echo "Используйте: $0 {START|STOP|STATUS}"
        exit 1
        ;;
esac

exit 0