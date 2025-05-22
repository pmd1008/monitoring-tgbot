#!/bin/bash
nohup ./monitoring-bot.sh > ./bot.log 2>&1 &
echo "Бот запущен. Логи: ./bot.log"
