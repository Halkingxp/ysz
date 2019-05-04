#!/bin/bash

# backup_mysql.sh
# This is a ShellScript For Auto DB Backup and Delete old Backup

BIN_DIR="/usr/bin" 
BACKUP_DIR="/home/server/database" 
DATE=` date +%Y_%m_%d `

$BIN_DIR/mysqldump -u root -pmysqladmin game_inst | gzip > $BACKUP_DIR/game_inst_$DATE.sql.gz
$BIN_DIR/mysqldump -u root -pmysqladmin game_log | gzip > $BACKUP_DIR/game_log_$DATE.sql.gz

find $BACKUP_DIR -name "game_inst*.sql.gz" -type f -mtime +7 -exec rm {} \; > /dev/null 2>&1
find $BACKUP_DIR -name "game_log*.sql.gz" -type f -mtime +7 -exec rm {} \; > /dev/null 2>&1