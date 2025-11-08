#!/bin/bash
# Анализ всех JRuby конфигураций без запуска Docker

set -e

echo "🔥 Анализ JRuby конфигураций Monitus"
echo "====================================="
echo

# Функция для анализа Dockerfile
analyze_dockerfile() {
    local dockerfile="$1"
    local name="$2"
    
    echo "📋 $name ($dockerfile)"
    echo "   Расположение: $dockerfile"
    
    if [ -f "$dockerfile" ]; then
        echo "   ✅ Файл существует"
        
        # Анализ базового образа
        base_image=$(grep -E "^FROM" "$dockerfile" | head -1 | awk '{print $2}' || echo "Unknown")
        echo "   📦 Базовый образ: $base_image"
        
        # Анализ портов
        ports=$(grep -E "^EXPOSE" "$dockerfile" | awk '{print $2}' | tr '\n' ' ' || echo "None")
        echo "   🔌 Порты: ${ports:-None}"
        
        # Анализ environment variables
        env_vars=$(grep -E "^ENV" "$dockerfile" | wc -l || echo 0)
        echo "   🌐 Environment переменных: $env_vars"
        
        # Поиск JRuby специфичных настроек
        if grep -q "JRUBY_OPTS" "$dockerfile"; then
            jruby_opts=$(grep "JRUBY_OPTS" "$dockerfile" | head -1)
            echo "   ⚡ JRuby оптимизации: найдены"
        else
            echo "   ⚠️  JRuby оптимизации: не найдены"
        fi
        
        # Поиск Java настроек
        if grep -q "JAVA_OPTS" "$dockerfile"; then
            echo "   ☕ Java настройки: найдены"
        else
            echo "   ⚠️  Java настройки: не найдены"
        fi
        
        # Анализ типа приложения
        if grep -q "passenger" "$dockerfile" 2>/dev/null; then
            echo "   🚢 Тип: Passenger интеграция"
        elif grep -q "puma" "$dockerfile" 2>/dev/null; then
            echo "   🐾 Тип: Puma standalone"
        elif grep -q "nginx" "$dockerfile" 2>/dev/null; then
            echo "   🌐 Тип: Nginx proxy"
        else
            echo "   🤷 Тип: Не определен"
        fi
        
        # Размер (приблизительная оценка по количеству команд)
        commands=$(grep -E "^(RUN|COPY|ADD)" "$dockerfile" | wc -l || echo 0)
        if [ $commands -lt 5 ]; then
            echo "   📏 Сложность: Минимальная ($commands команд)"
        elif [ $commands -lt 15 ]; then
            echo "   📏 Сложность: Средняя ($commands команд)"
        else
            echo "   📏 Сложность: Высокая ($commands команд)"
        fi
        
    else
        echo "   ❌ Файл не найден"
    fi
    echo
}

# Функция для анализа docker-compose файла
analyze_compose() {
    local compose_file="$1"
    local name="$2"
    
    echo "🐙 $name ($compose_file)"
    echo "   Расположение: $compose_file"
    
    if [ -f "$compose_file" ]; then
        echo "   ✅ Файл существует"
        
        # Количество сервисов
        services=$(grep -E "^  [a-zA-Z_]" "$compose_file" | grep -v "^  #" | wc -l || echo 0)
        echo "   🔧 Сервисов: $services"
        
        # JRuby сервисы
        jruby_services=$(grep -E "jruby" "$compose_file" | wc -l || echo 0)
        echo "   🔥 JRuby сервисов: $jruby_services"
        
        # Проверка health checks
        if grep -q "healthcheck" "$compose_file"; then
            echo "   💚 Health checks: найдены"
        else
            echo "   ⚠️  Health checks: не найдены"
        fi
        
        # Проверка environment variables
        env_sections=$(grep -E "environment:" "$compose_file" | wc -l || echo 0)
        echo "   🌐 Environment секций: $env_sections"
        
        # Сетевые настройки
        if grep -q "networks:" "$compose_file"; then
            echo "   🌐 Сети: настроены"
        else
            echo "   ⚠️  Сети: не настроены"
        fi
        
    else
        echo "   ❌ Файл не найден"
    fi
    echo
}

echo "1️⃣  АНАЛИЗ STANDALONE DOCKERFILES (src/)"
echo "============================================"

analyze_dockerfile "src/Dockerfile.jruby" "🚀 Основной JRuby standalone"
analyze_dockerfile "src/Dockerfile.jruby-minimal" "🔧 Минимальная сборка"
analyze_dockerfile "src/Dockerfile.jruby-minimal-debug" "🐛 Минимальная с отладкой"
analyze_dockerfile "src/Dockerfile.jruby-nginx" "🌐 JRuby + Nginx прокси"
analyze_dockerfile "src/Dockerfile.jruby-official-pattern" "📋 Официальный паттерн Passenger"
analyze_dockerfile "src/Dockerfile.jruby-passenger" "🚢 JRuby + Passenger полная"
analyze_dockerfile "src/Dockerfile.jruby-passenger-simple" "🚢 JRuby + Passenger упрощенная"
analyze_dockerfile "src/Dockerfile.jruby-test" "🧪 Для тестирования"
analyze_dockerfile "src/Dockerfile.jruby-working" "✅ Рабочая версия"

echo "2️⃣  АНАЛИЗ TEST DOCKERFILES (test/dockerfiles/)"
echo "==============================================="

analyze_dockerfile "test/dockerfiles/Dockerfile.jruby-with-app" "🎯 С тестовым приложением"
analyze_dockerfile "test/dockerfiles/Dockerfile.jruby-without-app" "🎯 Без тестового приложения"

echo "3️⃣  АНАЛИЗ DOCKER COMPOSE ФАЙЛОВ"
echo "=================================="

analyze_compose "test/docker-compose-jruby.yaml" "🏗️ Основные JRuby сервисы"
analyze_compose "test/docker-compose-jruby.ci.yaml" "🚀 CI конфигурация"
analyze_compose "test/docker-compose-jruby-passenger.yml" "🚢 Passenger специфичная"
analyze_compose "test/prometheus-jruby.yml" "📊 Prometheus интеграция"

echo "4️⃣  АНАЛИЗ КОНФИГУРАЦИОННЫХ ФАЙЛОВ"
echo "==================================="

# Анализ Gemfile.jruby
echo "💎 JRuby Gemfile (src/Gemfile.jruby)"
if [ -f "src/Gemfile.jruby" ]; then
    echo "   ✅ Файл существует"
    
    gems=$(grep -E "^gem " "src/Gemfile.jruby" | wc -l || echo 0)
    echo "   💎 Gem-ов: $gems"
    
    # Основные gems
    if grep -q "sinatra" "src/Gemfile.jruby"; then
        echo "   🌐 Sinatra: ✅"
    fi
    if grep -q "puma" "src/Gemfile.jruby"; then
        echo "   🐾 Puma: ✅"
    fi
    if grep -q "nokogiri" "src/Gemfile.jruby"; then
        echo "   📄 Nokogiri: ✅"
    fi
    if grep -q "prometheus-client" "src/Gemfile.jruby"; then
        echo "   📊 Prometheus client: ✅"
    fi
    
    # JRuby специфичные gems
    jruby_gems=$(grep -E "platforms.*jruby" "src/Gemfile.jruby" | wc -l || echo 0)
    echo "   🔥 JRuby специфичных gem-ов: $jruby_gems"
else
    echo "   ❌ Файл не найден"
fi
echo

# Анализ config.ru файлов
echo "⚙️  JRuby Config.ru файлы"
jruby_configs=$(find . -name "*.jruby" -type f | grep config | wc -l)
echo "   📋 JRuby config.ru файлов: $jruby_configs"
if [ $jruby_configs -gt 0 ]; then
    find . -name "*.jruby" -type f | grep config | while read config; do
        echo "   📄 $config"
    done
fi
echo

# Анализ shell скриптов
echo "📜 JRuby Shell скрипты"
jruby_scripts=$(find . -name "*.sh" -type f | grep -i jruby | wc -l)
echo "   🔧 JRuby скриптов: $jruby_scripts"
if [ $jruby_scripts -gt 0 ]; then
    find . -name "*.sh" -type f | grep -i jruby | while read script; do
        echo "   📜 $script"
    done
fi
echo

echo "5️⃣  ИТОГОВАЯ СВОДКА"
echo "=================="

# Подсчет общего количества конфигураций
total_dockerfiles=$(find . -name "Dockerfile*jruby*" -type f | wc -l)
total_compose=$(find . -name "*jruby*.yaml" -o -name "*jruby*.yml" | wc -l)
total_configs=$(find . -name "*jruby*" -type f | wc -l)

echo "📊 Статистика JRuby конфигураций:"
echo "   🐳 Dockerfile-ов: $total_dockerfiles"
echo "   🐙 Docker Compose файлов: $total_compose"
echo "   📄 Всего JRuby файлов: $total_configs"
echo

echo "🎯 Рекомендуемые варианты для тестирования:"
echo "   1. 🚀 Dockerfile.jruby - Основной standalone (рекомендуется начать с этого)"
echo "   2. 🚢 Dockerfile.jruby-passenger - Полная интеграция с Passenger"
echo "   3. 🔧 Dockerfile.jruby-minimal - Минимальная сборка для production"
echo "   4. 🐙 docker-compose-jruby.yaml - Все сервисы одновременно"
echo

echo "⚡ Команды для тестирования (если Docker доступен):"
echo "   # Makefile автоматизация"
echo "   cd test && make jruby-all"
echo
echo "   # Индивидуальная сборка"
echo "   cd src && docker build -f Dockerfile.jruby -t monitus-jruby ."
echo
echo "   # Docker Compose"
echo "   cd test && docker-compose -f docker-compose-jruby.yaml up"
echo

echo "✨ Анализ JRuby конфигураций завершен!"
echo "📚 См. JRUBY_TESTING_GUIDE.md для детальных инструкций"
