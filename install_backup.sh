#!/bin/bash
echo "=== Установка системы бэкапа n8n ==="

# Создаём папку для бэкапов
BACKUP_DIR="/root/n8n_backups"
mkdir -p "$BACKUP_DIR"
echo "✓ Папка для бэкапов создана: $BACKUP_DIR"

# Создаём скрипт бэкапа
cat > /root/backup_n8n.sh << 'BACKUP_SCRIPT'
#!/bin/bash
# Папка для бэкапов
BACKUP_DIR="/root/n8n_backups"
mkdir -p "$BACKUP_DIR"

# Имя файла с датой
BACKUP_FILE="$BACKUP_DIR/n8n_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Создаём бэкап папки n8n_data
cd /root
tar -czf "$BACKUP_FILE" n8n_data/

# Удаляем бэкапы старше 7 дней
find "$BACKUP_DIR" -name "n8n_backup_*.tar.gz" -mtime +7 -delete

echo "$(date): Backup created: $BACKUP_FILE" >> /root/n8n_backup.log
BACKUP_SCRIPT

# Делаем скрипт исполняемым
chmod +x /root/backup_n8n.sh
echo "✓ Скрипт бэкапа создан: /root/backup_n8n.sh"

# Добавляем в cron (каждый день в 2:00)
(crontab -l 2>/dev/null | grep -v "backup_n8n.sh"; echo "0 2 * * * /root/backup_n8n.sh") | crontab -
echo "✓ Добавлено в cron: ежедневный бэкап в 2:00"

# Создаём первый бэкап
echo "Создаём первый бэкап..."
bash /root/backup_n8n.sh

# Показываем результат
echo ""
echo "=== Установка завершена ==="
echo "Созданные бэкапы:"
ls -lh "$BACKUP_DIR/"
echo ""
echo "Настройки cron:"
crontab -l | grep backup_n8n.sh
echo ""
echo "Логи бэкапов: /root/n8n_backup.log"
