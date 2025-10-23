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

# Проверяем размер файла (в мегабайтах)
FILE_SIZE=$(du -m "$BACKUP_FILE" | cut -f1)

if [ $FILE_SIZE -le 100 ]; then
    echo "$(date): Backup size ${FILE_SIZE}MB, uploading to GitHub..." >> /root/n8n_backup.log
    
    # Клонируем/обновляем репозиторий через SSH
    REPO_DIR="/tmp/n8n_backup_repo"
    if [ -d "$REPO_DIR" ]; then
        cd "$REPO_DIR"
        git pull origin main
    else
        git clone git@github.com:nizrem/n8n_vp2_backup.git "$REPO_DIR"
        cd "$REPO_DIR"
    fi
    
    # Копируем бэкап
    cp "$BACKUP_FILE" "$REPO_DIR/"
    
    # Пушим в GitHub
    git add "$(basename $BACKUP_FILE)"
    git commit -m "Auto backup $(date +%Y-%m-%d_%H:%M:%S)"
    git push origin main
    
    if [ $? -eq 0 ]; then
        echo "$(date): Backup uploaded to GitHub successfully" >> /root/n8n_backup.log
    else
        echo "$(date): Failed to upload backup to GitHub" >> /root/n8n_backup.log
    fi
else
    echo "$(date): Backup size ${FILE_SIZE}MB exceeds 100MB limit, skipping GitHub upload" >> /root/n8n_backup.log
fi
BACKUP_SCRIPT

# Делаем скрипт исполняемым
chmod +x /root/backup_n8n.sh
echo "✓ Скрипт бэкапа создан: /root/backup_n8n.sh"

# Настраиваем Git
git config --global user.email "nizrem@gmail.com"
git config --global user.name "nizrem"
echo "✓ Git настроен"

# Добавляем в cron (очистка в 8:00, бэкап в 9:00)
(crontab -l 2>/dev/null | grep -v "backup_n8n.sh" | grep -v "binaryData"; echo "0 8 * * * find /root/n8n_data/binaryData -type f -delete"; echo "0 9 * * * /root/backup_n8n.sh") | crontab -
echo "✓ Добавлено в cron: очистка binaryData в 8:00, бэкап в 9:00"

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
crontab -l | grep -E "backup_n8n|binaryData"
echo ""
echo "Логи бэкапов: /root/n8n_backup.log"
