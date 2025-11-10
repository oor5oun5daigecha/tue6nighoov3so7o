#!/bin/bash
# Quick check for Passenger Nginx module installation

echo "🔍 Проверка установки Passenger модуля для Nginx"
echo "================================================="
echo

echo "📦 Проверка установленных пакетов:"
if command -v dpkg &> /dev/null; then
    echo "✅ nginx packages:"
    dpkg -l | grep nginx | awk '{print "   " $2 " - " $3}'
    echo
    echo "✅ passenger packages:"
    dpkg -l | grep passenger | awk '{print "   " $2 " - " $3}'
else
    echo "⚠️  dpkg не найден, пропускаем проверку пакетов"
fi

echo
echo "🔍 Поиск Passenger модуля:"
if [ -f "/usr/lib/nginx/modules/ngx_http_passenger_module.so" ]; then
    echo "✅ Модуль найден: /usr/lib/nginx/modules/ngx_http_passenger_module.so"
else
    echo "❌ Модуль не найден в стандартном пути"
    echo "🔍 Ищем в других местах..."
    find /usr -name "*passenger*.so" 2>/dev/null | while read file; do
        echo "   📍 $file"
    done
fi

echo
echo "📋 Проверка конфигурации Nginx:"
if [ -f "/etc/nginx/modules-enabled/50-mod-http-passenger.conf" ]; then
    echo "✅ Конфиг модуля найден:"
    cat /etc/nginx/modules-enabled/50-mod-http-passenger.conf | sed 's/^/   /'
else
    echo "❌ Конфигурация модуля не найдена"
fi

echo
if command -v nginx &> /dev/null; then
    echo "🧪 Тест конфигурации Nginx:"
    if nginx -t 2>&1; then
        echo "✅ Конфигурация Nginx корректна"
    else
        echo "❌ Ошибка в конфигурации Nginx"
    fi
else
    echo "⚠️  nginx команда недоступна"
fi

echo
if command -v passenger-config &> /dev/null; then
    echo "🔧 Информация о Passenger:"
    echo "   Версия: $(passenger-config --version)"
    echo "   Ruby: $(passenger-config --ruby-command | head -1)"
    if passenger-config --detect-apache &>/dev/null || passenger-config --detect-nginx &>/dev/null; then
        echo "✅ Passenger integration detected"
    fi
else
    echo "⚠️  passenger-config недоступен"
fi

echo
echo "📝 Рекомендации:"
echo "1. Убедитесь что установлен пакет: libnginx-mod-http-passenger"
echo "2. Проверьте что модуль загружается в /etc/nginx/modules-enabled/"
echo "3. Используйте 'nginx -t' для проверки конфигурации"
echo "4. Перезапустите nginx после изменений"
