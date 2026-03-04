#!/bin/bash
# ==============================================================================
# Установка Prometheus Node Exporter на Ubuntu
# Copyleft(c) by Denis Astahov | Доработка: devcloud13 (https://github.com/devcloud13)
# Оригинал: https://github.com/adv4000/prometheus
# ==============================================================================

set -e  # Остановить скрипт при любой ошибке
set -u  # Ошибка если переменная не задана

# ------------------------------------------------------------------------------
# ВЕРСИЯ — автоматически получаем последнюю с GitHub
# Если GitHub недоступен — используем fallback
# ------------------------------------------------------------------------------
FALLBACK_VERSION="1.7.0"
echo -e "\033[0;32m[ИНФО]\033[0m Определяем последнюю версию Node Exporter..."
NODE_EXPORTER_VERSION=$(curl -sf https://api.github.com/repos/prometheus/node_exporter/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//') || NODE_EXPORTER_VERSION="$FALLBACK_VERSION"
echo -e "\033[0;32m[ИНФО]\033[0m Версия для установки: ${NODE_EXPORTER_VERSION}"

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
# Проверка: уже установлен?
# ------------------------------------------------------------------------------
if systemctl is-active --quiet node_exporter 2>/dev/null; then
    warn "Node Exporter уже запущен!"
    warn "Текущая версия: $(node_exporter --version 2>&1 | head -1)"
    read -r -p "Переустановить? (y/N): " REPLY
    [[ "$REPLY" =~ ^[Yy]$ ]] || { log "Установка отменена."; exit 0; }
    log "Останавливаем существующий Node Exporter..."
    systemctl stop node_exporter
fi

# ------------------------------------------------------------------------------
# Проверка что запущен от root
# ------------------------------------------------------------------------------
[[ $EUID -eq 0 ]] || error "Запусти скрипт от root: sudo $0"

# ------------------------------------------------------------------------------
# Установка
# ------------------------------------------------------------------------------
log "Скачиваем Node Exporter v${NODE_EXPORTER_VERSION}..."
cd /tmp
wget -q --show-progress \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
    -O node_exporter.tar.gz

log "Распаковываем..."
tar xzf node_exporter.tar.gz
cd "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"

log "Создаём пользователя..."
id node_exporter &>/dev/null || useradd --no-create-home --shell /bin/false node_exporter

log "Копируем бинарник..."
cp node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

log "Создаём systemd-сервис..."
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \\
    --collector.systemd \\
    --collector.processes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

log "Запускаем Node Exporter..."
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# ------------------------------------------------------------------------------
# Очистка временных файлов
# ------------------------------------------------------------------------------
log "Удаляем временные файлы..."
cd /tmp
rm -rf node_exporter.tar.gz "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"

# ------------------------------------------------------------------------------
# Готово
# ------------------------------------------------------------------------------
echo ""
log "========================================"
log "Node Exporter v${NODE_EXPORTER_VERSION} установлен!"
log "Метрики: http://$(hostname -I | awk '{print $1}'):9100/metrics"
log "Статус:  systemctl status node_exporter"
log "Логи:    journalctl -u node_exporter -f"
log ""
log "Добавь в prometheus.yml в секцию scrape_configs:"
log "  - job_name: 'node'"
log "    static_configs:"
log "      - targets: ['$(hostname -I | awk '{print $1}'):9100']"
log "========================================"
