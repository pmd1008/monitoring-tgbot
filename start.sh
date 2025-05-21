#!/bin/bash
nohup /home/pmd/monitoring-bot/monitoring-bot.sh > /home/pmd/monitoring-bot/bot.log 2>&1 &
echo "Бот запущен. Логи: /home/pmd/monitoring-bot/bot.log"
