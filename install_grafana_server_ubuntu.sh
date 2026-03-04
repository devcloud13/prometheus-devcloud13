#!/bin/bash
# ==============================================================================
# Установка Grafana Server на Ubuntu
# Copyleft(c) by Denis Astahov | Доработка: devcloud13 (https://github.com/devcloud13)
# Оригинал: https://github.com/adv4000/prometheus
# ==============================================================================

set -e  # Остановить скрипт при любой ошибке
set -u  # Ошибка если переменная не задана

# ------------------------------------------------------------------------------
# ВЕРСИЯ — автоматически получаем последнюю с GitHub
# Если GitHub недоступен — используем fallback
# ------------------------------------------------------------------------------
FALLBACK_VERSION="10.4.2"
echo -e "\033[0;32m[ИНФО]\033[0m Определяем последнюю версию Grafana..."
GRAFANA_VERSION=$(curl -sf https://api.github.com/repos/grafana/grafana/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//') || GRAFANA_VERSION="$FALLBACK_VERSION"
echo -e "\033[0;32m[ИНФО]\033[0m Версия для установки: ${GRAFANA_VERSION}"

# ------------------------------------------------------------------------------
# Цвета для вывода
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[ИНФО]${NC} $1"; }
warn()  { echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"; }
error() { echo -e "${RED}[ОШИБКА]${NC} $1"; exit 1; }

# ------------------------------------------------------------------------------
# Проверка: уже установлена?
# ------------------------------------------------------------------------------
if systemctl is-active --quiet grafana-server 2>/dev/null; then
    warn "Grafana уже запущена!"
    warn "Текущая версия: $(grafana-server -v 2>&1 | head -1)"
    read -r -p "Переустановить? (y/N): " REPLY
    [[ "$REPLY" =~ ^[Yy]$ ]] || { log "Установка отменена."; exit 0; }
    log "Останавливаем существующую Grafana..."
    systemctl stop grafana-server
fi

# ------------------------------------------------------------------------------
# Проверка что запущен от root
# ------------------------------------------------------------------------------
[[ $EUID -eq 0 ]] || error "Запусти скрипт от root: sudo $0"

# ------------------------------------------------------------------------------
# Установка зависимостей
# ------------------------------------------------------------------------------
log "Устанавливаем зависимости..."
apt-get update -qq
apt-get install -y -qq apt-transport-https software-properties-common wget curl gnupg

# ------------------------------------------------------------------------------
# Добавляем репозиторий Grafana
# ------------------------------------------------------------------------------
log "Добавляем репозиторий Grafana..."
mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
    > /etc/apt/sources.list.d/grafana.list

# ------------------------------------------------------------------------------
# Установка Grafana
# ------------------------------------------------------------------------------
log "Устанавливаем Grafana v${GRAFANA_VERSION}..."
apt-get update -qq
apt-get install -y -qq "grafana=${GRAFANA_VERSION}"

# ------------------------------------------------------------------------------
# Запуск
# ------------------------------------------------------------------------------
log "Запускаем Grafana..."
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# ------------------------------------------------------------------------------
# Готово
# ------------------------------------------------------------------------------
echo ""
log "========================================"
log "Grafana v${GRAFANA_VERSION} установлена!"
log "Веб-интерфейс: http://$(hostname -I | awk '{print $1}'):3000"
log "Логин:         admin / admin  (смени при первом входе!)"
log "Конфиг:        /etc/grafana/grafana.ini"
log "Логи:          journalctl -u grafana-server -f"
log "Статус:        systemctl status grafana-server"
log ""
log "Следующие шаги:"
log "  1. Открой Grafana в браузере"
log "  2. Добавь datasource Prometheus: http://localhost:9090"
log "  3. Импортируй дашборд ID 1860 (Node Exporter Full)"
log "========================================"
