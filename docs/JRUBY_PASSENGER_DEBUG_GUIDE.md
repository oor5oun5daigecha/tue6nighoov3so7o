# JRuby + Passenger + Nginx Debug Guide 🚀

## Quick Start

Для быстрого запуска отладочной конфигурации:

```bash
# 1. Диагностика конфигурации
./diagnose-jruby-passenger-config.sh

# 2. Запуск debug контейнера
docker-compose -f docker-compose.jruby-passenger-debug.yml up --build

# 3. Интерактивная отладка
./debug-jruby-passenger.sh
```

## Конфигурация

### Основные файлы:
- **Dockerfile:** `src/Dockerfile.jruby-passenger`
- **Nginx:** `src/nginx-jruby.conf` 
- **Passenger:** `src/passenger-jruby.conf`
- **App Config:** `src/config.ru.jruby`
- **Gems:** `src/Gemfile.jruby`

### Архитектура:
```
[Nginx :80] → [Passenger] → [JRuby App] → [Prometheus Metrics]
      ↓              ↓            ↓              ↓
   Proxy &       Process      Ruby VM      /monitus/metrics
   Static       Management    Threading     /health
   Files
```

## Endpoints для тестирования

```bash
# Health check
curl http://localhost:8080/health

# Prometheus metrics
curl http://localhost:8080/monitus/metrics

# Passenger status (JSON)
curl http://localhost:8080/monitus/passenger-status-node_json

# Passenger status (Prometheus format)
curl http://localhost:8080/monitus/passenger-status-node_prometheus

# Root endpoint
curl http://localhost:8080/
```

## Отладка проблем

### 1. Контейнер не запускается
```bash
# Проверить логи сборки
docker-compose -f docker-compose.jruby-passenger-debug.yml build --no-cache

# Проверить логи контейнера
docker logs jruby-passenger-debug
```

### 2. Passenger не стартует
```bash
# Войти в контейнер
docker exec -it jruby-passenger-debug /bin/bash

# Проверить Passenger статус
passenger-status

# Проверить конфигурацию
passenger-config validate-install

# Проверить JRuby
jruby --version
java -version
```

### 3. Приложение не отвечает
```bash
# Проверить процессы
docker exec jruby-passenger-debug ps aux

# Проверить порты
docker exec jruby-passenger-debug netstat -tlnp

# Проверить логи nginx
docker exec jruby-passenger-debug tail -f /var/log/nginx/error.log

# Проверить логи приложения
docker exec jruby-passenger-debug passenger-status --verbose
```

### 4. Медленная работа
```bash
# Мониторинг JVM
docker exec jruby-passenger-debug jruby -e "
  require 'java'
  runtime = Java::JavaLang::Runtime.getRuntime
  total = runtime.totalMemory / 1024 / 1024
  used = (runtime.totalMemory - runtime.freeMemory) / 1024 / 1024
  puts \"JVM Memory: #{used}MB / #{total}MB\"
"

# Passenger memory stats
docker exec jruby-passenger-debug passenger-memory-stats

# Thread dump
docker exec jruby-passenger-debug passenger-status --show=xml | grep -i thread
```

## Оптимизация производительности

### JRuby настройки:
```bash
JRUBY_OPTS="-Xcompile.invokedynamic=true -J-Djnr.ffi.asm.enabled=false"
JAVA_OPTS="-Xmx2G -Xms512M -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Passenger настройки:
```nginx
passenger_spawn_method direct;          # !! Критично для JRuby
passenger_concurrency_model thread;     # Используем JRuby threading
passenger_thread_count 16;              # 16-32 для production
passenger_min_instances 2;              # Минимум процессов
passenger_max_instances 8;              # Максимум процессов
passenger_memory_limit 1024;            # Лимит памяти (MB)
```

### Nginx настройки:
```nginx
worker_processes auto;
worker_connections 1024;
gzip on;
gzip_types text/plain application/json text/css application/javascript;
```

## Мониторинг

### Prometheus метрики:
- `passenger_capacity` - общая емкость
- `passenger_processes` - количество процессов
- `passenger_request_queue` - очередь запросов
- `passenger_memory_usage` - использование памяти

### Grafana dashboard:
```bash
# Добавить Prometheus: http://prometheus-debug:9090
# Импортировать Passenger dashboard
```

## Troubleshooting чеклист

- [ ] ✅ JRuby версия 9.4+ установлена
- [ ] ✅ `passenger_spawn_method direct` в конфигурации  
- [ ] ✅ `passenger_concurrency_model thread` настроено
- [ ] ✅ JRuby gems в `Gemfile.jruby` (jruby-openssl, jrjackson)
- [ ] ✅ Нет MRI-specific gems (thin, unicorn, eventmachine)
- [ ] ✅ `config.ru.jruby` используется как entry point
- [ ] ✅ JAVA_OPTS и JRUBY_OPTS настроены
- [ ] ✅ Достаточно памяти выделено (минимум 1GB)
- [ ] ✅ Health check endpoints отвечают
- [ ] ✅ Passenger status показывает активные процессы

## Контакты и поддержка

Если проблемы продолжаются:
1. Запустите полную диагностику: `./diagnose-jruby-passenger-config.sh`
2. Соберите логи: `docker logs jruby-passenger-debug > debug.log`
3. Проверьте известные проблемы в JRUBY_SUPPORT.md

**Happy debugging! 🎯**
