#!/bin/bash

# Путь к файлу конфигурации
CONFIG_FILE="config.conf"

# Проверяем наличие файла конфигурации
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Ошибка: Файл конфигурации $CONFIG_FILE не найден."
    echo "Создайте $CONFIG_FILE с переменной TOKEN=\"ВАШ_ТОКЕН_БОТА\""
    exit 1
fi

# Загружаем конфигурацию
source "$CONFIG_FILE"


# Проверяем, задан ли TOKEN
if [[ -z "$TOKEN" ]]; then
    echo "Ошибка: Переменная TOKEN не задана в $CONFIG_FILE."
    exit 1
fi

# Формируем URL API Telegram
API_URL="https://api.telegram.org/bot$TOKEN"



# Функция для отправки сообщений в Telegram
send_message() {
    local chat_id=$1
    local text=$2
    local reply_markup=$3
    # Отправляем POST к Telegram
    curl -s -X POST "$API_URL/sendMessage" \
        -d chat_id="$chat_id" \
        -d text="$text" \
        -d parse_mode="Markdown" \
        -d reply_markup="$reply_markup" > /dev/null #очистка ответа
}

# Функция для сбора информации о сервере
get_server_info() {
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
    mem=$(free -m | awk '/Mem:/ {printf "%.2f%%", $3/$2 * 100}')
    disk=$(df -h / | awk '/\// {print $5}')
    # Формируем текст в Markdown(кнопка для запроса инфы)
    echo -e "📊 *Информация о сервере:*\n- *CPU*: $cpu%\n- *Память*: $mem\n- *Диск*: $disk"
}

# Функция для создания кнопки в формате JSON
get_reply_markup() {
    # JSON с одной кнопкой: текст "Обновить данные 🔄", callback_data "refresh"
    echo '{"inline_keyboard":[[{"text":"Обновить данные 🔄","callback_data":"refresh"}]]}'
}

# Основной цикл обработки обновлений
OFFSET=0  # Хранит ID последнего обработанного обновления
while true; do
    # Получаем обновления через GET-запрос
    updates=$(curl -s -X GET "$API_URL/getUpdates?offset=$OFFSET")
    
    # Проверяем, есть ли обновления
    if [[ $(echo "$updates" | jq '.result | length') -gt 0 ]]; then
        # кодируем обновления в base64, для того чтобы фор не ломался 
        for row in $(echo "$updates" | jq -r '.result[] | @base64'); do
            update=$(echo "$row" | base64 --decode)
            chat_id=$(echo "$update" | jq -r '.message.chat.id // .callback_query.message.chat.id')   # Извлекаем chat_id (из message или callback_query)
            text=$(echo "$update" | jq -r '.message.text // ""')                                      # Извлекаем сообщение пользователя, либо кнопка, либо текст
            
            callback_data=$(echo "$update" | jq -r '.callback_query.data // ""')
            
            # Обновляем OFFSET
            update_id=$(echo "$update" | jq -r '.update_id')
            OFFSET=$((update_id + 1))
            
            if [[ "$text" == "/serverinfo" || "$callback_data" == "refresh" ]]; then   # Обрабатываем /serverinfo или нажатие кнопки
                # Получаем информацию о сервере
                server_info=$(get_server_info)
                reply_markup=$(get_reply_markup)
                # Отправляем новое сообщение
                send_message "$chat_id" "$server_info" "$reply_markup"
            fi
        done
    fi
    
    sleep 1
done
