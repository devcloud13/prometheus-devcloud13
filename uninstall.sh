#!/bin/bash
# ==============================================================================
# Удаление Prometheus + Node Exporter + Grafana с Ubuntu
# Copyleft(c) by Denis Astahov | Доработка: devcloud13 (https://github.com/devcloud13)
# Оригинал: https://github.com/adv4000/prometheus
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[ИНФО]${NC} $1"; }
warn()  { echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"; }
error() { echo -e "${RED}[ОШИБКА]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] || error "Запусти скрипт от root: sudo $0"

echo -e "${RED}"
echo "  ██╗   ██╗██████╗  █████╗ ██╗     ███████╗███╗   ██╗██╗███████╗"
echo "  ██║   ██║██╔══██╗██╔══██╗██║     ██╔════╝████╗  ██║██║██╔════╝"
echo "  ██║   ██║██║  ██║███████║██║     █████╗  ██╔██╗ ██║██║█████╗  "
echo "  ██║   ██║██║  ██║██╔══██║██║     ██╔══╝  ██║╚██╗██║██║██╔══╝  "
echo "  ╚██████╔╝██████╔╝██║  ██║███████╗███████╗██║ ╚████║██║███████╗ "
echo "   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝╚══════╝"
echo -e "${NC}"
warn "Это действие ПОЛНОСТЬЮ удалит Prometheus, Node Exporter и Grafana!"
warn "Все данные и конфиги будут уничтожены!"
echo ""
read -r -p "Вы уверены? Введите 'yes' для подтверждения: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { log "Отменено."; exit 0; }

# ------------------------------------------------------------------------------
# Prometheus
# ------------------------------------------------------------------------------
log "Удаляем Prometheus..."
systemctl stop prometheus 2>/dev/null && log "  Сервис prometheus остановлен" || warn "  prometheus не был запущен"
systemctl disable prometheus 2>/dev/null || true
rm -f /etc/systemd/system/prometheus.service
rm -f /usr/local/bin/prometheus /usr/local/bin/promtool
rm -rf /etc/prometheus /var/lib/prometheus
id prometheus &>/dev/null && userdel prometheus && log "  Пользователь 'prometheus' удалён" || true
log "  Prometheus удалён."

# ------------------------------------------------------------------------------
# Node Exporter
# ------------------------------------------------------------------------------
log "Удаляем Node Exporter..."
systemctl stop node_exporter 2>/dev/null && log "  Сервис node_exporter остановлен" || warn "  node_exporter не был запущен"
systemctl disable node_exporter 2>/dev/null || true
rm -f /etc/systemd/system/node_exporter.service
rm -f /usr/local/bin/node_exporter
id node_exporter &>/dev/null && userdel node_exporter && log "  Пользователь 'node_exporter' удалён" || true
log "  Node Exporter удалён."

# ------------------------------------------------------------------------------
# Grafana
# ------------------------------------------------------------------------------
log "Удаляем Grafana..."
systemctl stop grafana-server 2>/dev/null && log "  Сервис grafana-server остановлен" || warn "  grafana-server не был запущен"
systemctl disable grafana-server 2>/dev/null || true
apt-get remove --purge -y -qq grafana 2>/dev/null || true
rm -f /etc/apt/sources.list.d/grafana.list
rm -f /etc/apt/keyrings/grafana.gpg
rm -rf /etc/grafana /var/lib/grafana /var/log/grafana
log "  Grafana удалена."

# ------------------------------------------------------------------------------
# Перезагружаем systemd
# ------------------------------------------------------------------------------
systemctl daemon-reload
apt-get autoremove -y -qq 2>/dev/null || true

# ------------------------------------------------------------------------------
# Готово
# ------------------------------------------------------------------------------
echo ""
log "========================================"
log "Все компоненты успешно удалены!"
log "Для повторной установки запусти install-скрипты."
log "========================================"
