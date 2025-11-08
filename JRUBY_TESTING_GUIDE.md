# JRuby Контейнеры: Полное руководство по тестированию

Это руководство поможет опробовать все доступные варианты запуска JRuby контейнеров в проекте Monitus.

## 🔍 Обзор всех JRuby конфигураций

### 📁 Standalone Dockerfiles (src/)
```
src/Dockerfile.jruby                    # 🚀 Основной JRuby standalone
src/Dockerfile.jruby-minimal           # 🔧 Минимальная сборка
src/Dockerfile.jruby-minimal-debug     # 🐛 Минимальная с отладкой
src/Dockerfile.jruby-nginx             # 🌐 JRuby + Nginx прокси
src/Dockerfile.jruby-official-pattern  # 📋 Официальный паттерн Passenger
src/Dockerfile.jruby-passenger         # 🚂 JRuby + Passenger полная
src/Dockerfile.jruby-passenger-simple  # 🚂 JRuby + Passenger упрощенная
src/Dockerfile.jruby-test              # 🧪 Для тестирования
src/Dockerfile.jruby-working           # ✅ Рабочая версия
```

### 📁 Test Dockerfiles (test/dockerfiles/)
```
test/dockerfiles/Dockerfile.jruby-with-app     # 🎯 С тестовым приложением
test/dockerfiles/Dockerfile.jruby-without-app  # 🎯 Без тестового приложения
```

### 📁 Docker Compose файлы
```
test/docker-compose-jruby.yaml             # 🏗️ Основные JRuby сервисы
test/docker-compose-jruby.ci.yaml          # 🚀 CI конфигурация
test/docker-compose-jruby-passenger.yml    # 🚂 Passenger специфичная
test/prometheus-jruby.yml                   # 📊 Prometheus интеграция
```

## 🚀 Способы тестирования

### Метод 1: Through Docker Compose (Рекомендуемый)
```bash
# Все JRuby сервисы одновременно
cd test
make jruby-run

# Или вручную
docker-compose -f docker-compose-jruby.yaml up
```

### Метод 2: Individual Docker Build & Run
```bash
# Каждый Dockerfile отдельно
cd src
docker build -f Dockerfile.jruby -t monitus-jruby .
docker run -p 8080:8080 monitus-jruby
```

### Метод 3: Automated Testing
```bash
# Полное тестирование
cd test
make jruby-test

# Только сборка
make jruby-build
```

### Метод 4: CI-style Testing
```bash
# Как в CI
cd test
make jruby-test-ci
```

## 📋 Detailed Testing Steps

### 1. 🚀 Основной JRuby Standalone (Dockerfile.jruby)

**Что это:** Самостоятельный JRuby контейнер с Puma сервером

```bash
cd src

# Сборка
docker build -f Dockerfile.jruby -t monitus-jruby .

# Запуск
docker run -d --name monitus-jruby \
  -p 8080:8080 \
  -e JRUBY_OPTS="-Xcompile.invokedynamic=true" \
  -e JAVA_OPTS="-Xmx1G -Xms256M -XX:+UseG1GC" \
  monitus-jruby

# Проверка
curl http://localhost:8080/health
curl http://localhost:8080/monitus/metrics

# Логи
docker logs monitus-jruby

# Очистка
docker stop monitus-jruby
docker rm monitus-jruby
```

**Ожидаемый результат:**
- ✅ Быстрый старт (~30s)
- ✅ Prometheus метрики доступны
- ✅ JRuby оптимизации активны

### 2. 🔧 Minimal JRuby (Dockerfile.jruby-minimal)

**Что это:** Минимальная сборка только с essential gems

```bash
cd src

# Сборка
docker build -f Dockerfile.jruby-minimal -t monitus-jruby-minimal .

# Запуск
docker run -d --name monitus-minimal \
  -p 8081:8080 \
  monitus-jruby-minimal

# Проверка
curl http://localhost:8081/health

# Размер образа
docker images | grep monitus-jruby-minimal

# Очистка
docker stop monitus-minimal && docker rm monitus-minimal
```

**Ожидаемый результат:**
- ✅ Меньший размер образа
- ✅ Быстрая сборка
- ⚠️ Ограниченный функционал

### 3. 🐛 Debug Minimal (Dockerfile.jruby-minimal-debug)

**Что это:** Minimal версия с отладочной информацией

```bash
cd src

# Сборка с verbose output
docker build -f Dockerfile.jruby-minimal-debug -t monitus-debug . --progress=plain

# Запуск с debug режимом
docker run -d --name monitus-debug \
  -p 8082:8080 \
  -e LOG_LEVEL=debug \
  monitus-debug

# Интерактивный режим для отладки
docker run -it --rm monitus-debug /bin/bash

# Очистка
docker stop monitus-debug && docker rm monitus-debug
```

### 4. 🌐 JRuby + Nginx Proxy (Dockerfile.jruby-nginx)

**Что это:** JRuby app за Nginx прокси

```bash
cd src

# Сборка
docker build -f Dockerfile.jruby-nginx -t monitus-nginx .

# Запуск
docker run -d --name monitus-nginx \
  -p 8083:80 \
  -p 8084:8080 \
  monitus-nginx

# Проверка через Nginx (порт 80)
curl http://localhost:8083/monitus/metrics

# Прямая проверка JRuby (порт 8080)
curl http://localhost:8084/monitus/metrics

# Проверка Nginx конфигурации
docker exec monitus-nginx nginx -t

# Очистка
docker stop monitus-nginx && docker rm monitus-nginx
```

### 5. 🚂 JRuby + Passenger (Dockerfile.jruby-passenger)

**Что это:** Полная интеграция JRuby с Passenger

```bash
cd src

# Сборка (может занять больше времени)
docker build -f Dockerfile.jruby-passenger -t monitus-passenger .

# Запуск
docker run -d --name monitus-passenger \
  -p 8085:80 \
  -e PASSENGER_SPAWN_METHOD=direct \
  monitus-passenger

# Проверка
curl http://localhost:8085/monitus/metrics

# Passenger статус (если доступен)
docker exec monitus-passenger passenger-status 2>/dev/null || echo "passenger-status not available"

# Очистка
docker stop monitus-passenger && docker rm monitus-passenger
```

### 6. 📋 Official Pattern (Dockerfile.jruby-official-pattern)

**Что это:** Следует официальным паттернам Phusion Passenger

```bash
cd src

# Сборка
docker build -f Dockerfile.jruby-official-pattern -t monitus-official .

# Запуск
docker run -d --name monitus-official \
  -p 8086:80 \
  monitus-official

# Проверка
curl http://localhost:8086/monitus/metrics

# Проверка Passenger native support
docker exec monitus-official ls -la /usr/local/rvm/gems/*/gems/passenger-*/buildout/

# Очистка
docker stop monitus-official && docker rm monitus-official
```

### 7. 🧪 Test Container (Dockerfile.jruby-test)

**Что это:** Специально для автоматического тестирования

```bash
cd src

# Сборка
docker build -f Dockerfile.jruby-test -t monitus-test .

# Запуск тестов
docker run --rm monitus-test

# Интерактивный режим
docker run -it --rm monitus-test /bin/bash
```

## 🏗️ Docker Compose тестирование

### Основная конфигурация
```bash
cd test

# Запуск всех JRuby сервисов
docker-compose -f docker-compose-jruby.yaml up -d

# Проверка статуса
docker-compose -f docker-compose-jruby.yaml ps

# Проверка логов
docker-compose -f docker-compose-jruby.yaml logs -f

# Тестирование сервисов
curl http://localhost:10254/monitus/metrics  # passenger_jruby_with_app
curl http://localhost:8080/health            # monitus_jruby_standalone

# Остановка
docker-compose -f docker-compose-jruby.yaml down
```

### CI конфигурация
```bash
cd test

# Запуск в CI режиме
docker-compose -f docker-compose-jruby.ci.yaml up -d

# Запуск тестов
docker-compose -f docker-compose-jruby.ci.yaml run --rm test_jruby

# Очистка
docker-compose -f docker-compose-jruby.ci.yaml down
```

## 📊 Автоматизированное тестирование через Makefile

### Полный цикл тестирования
```bash
cd test

# Полное JRuby тестирование
make jruby-all

# Пошагово:
make jruby-clean    # Очистка
make jruby-build    # Сборка всех образов
make jruby-test     # Запуск тестов
make jruby-run      # Запуск для разработки
```

### Отдельные команды
```bash
# Только сборка
make jruby-build

# Только тестирование (требует готовых образов)
make jruby-test

# Запуск для разработки
make jruby-run

# CI тестирование
make jruby-test-ci

# Логи
make jruby-logs

# Статус
make jruby-status

# Очистка
make jruby-clean
```

## 🔍 Диагностика и отладка

### Проверка JRuby версии и оптимизаций
```bash
# В любом JRuby контейнере
docker exec <container_name> jruby -v
docker exec <container_name> jruby -e "puts JRUBY_VERSION"
docker exec <container_name> env | grep JRUBY
docker exec <container_name> env | grep JAVA
```

### Проверка gem-ов
```bash
# Список установленных gem-ов
docker exec <container_name> jruby -S gem list

# Проверка bundler
docker exec <container_name> jruby -S bundle --version
```

### Проверка приложения
```bash
# Проверка синтаксиса
docker exec <container_name> jruby -c /app/prometheus_exporter.rb

# Тест загрузки приложения
docker exec <container_name> jruby -e "require_relative '/app/prometheus_exporter'; puts 'App loaded successfully'"
```

## ⚡ Performance тестирование

### Простая нагрузка
```bash
# Установка apache bench (если нужно)
# apt-get install apache2-utils

# Тестирование производительности
ab -n 1000 -c 10 http://localhost:8080/health
ab -n 100 -c 5 http://localhost:8080/monitus/metrics

# Или с curl в цикле
for i in {1..100}; do
  curl -s http://localhost:8080/health > /dev/null
  echo "Request $i completed"
done
```

### Мониторинг ресурсов
```bash
# Использование памяти и CPU
docker stats <container_name>

# Детальная информация
docker exec <container_name> ps aux
docker exec <container_name> free -h
docker exec <container_name> df -h
```

## 🎯 Рекомендуемая последовательность тестирования

1. **Начните с Makefile автоматизации:**
   ```bash
   cd test
   make jruby-all
   ```

2. **Тестируйте основной standalone:**
   ```bash
   cd src
   docker build -f Dockerfile.jruby -t monitus-jruby .
   docker run -p 8080:8080 monitus-jruby
   ```

3. **Опробуйте Passenger интеграцию:**
   ```bash
   docker build -f Dockerfile.jruby-passenger -t monitus-passenger .
   docker run -p 8085:80 monitus-passenger
   ```

4. **Проверьте minimal версии для production:**
   ```bash
   docker build -f Dockerfile.jruby-minimal -t monitus-minimal .
   docker run -p 8081:8080 monitus-minimal
   ```

5. **Используйте debug версии при проблемах:**
   ```bash
   docker build -f Dockerfile.jruby-minimal-debug -t monitus-debug .
   docker run -it monitus-debug /bin/bash
   ```

## 🚨 Troubleshooting

### Частые проблемы и решения

1. **Медленный старт JRuby:**
   - Ожидайте 30-60 секунд для первого запроса
   - Используйте JAVA_OPTS для настройки JVM

2. **Out of Memory ошибки:**
   ```bash
   # Увеличьте heap size
   -e JAVA_OPTS="-Xmx2G -Xms512M"
   ```

3. **Passenger spawn проблемы:**
   ```bash
   # Используйте direct spawn method
   -e PASSENGER_SPAWN_METHOD=direct
   ```

4. **Port conflicts:**
   ```bash
   # Используйте разные порты для каждого контейнера
   -p 8080:8080  # основной
   -p 8081:8080  # minimal
   -p 8082:8080  # debug
   ```

Теперь у вас есть полное руководство для тестирования всех JRuby конфигураций! 🎉
