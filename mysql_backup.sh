#!/bin/bash
#==============================================================================
#TITLE:            mysql_backup.sh
#DESCRIPTION:      script for automating the daily mysql backups on development computer
#AUTHOR:           tleish
#DATE:             2013-12-20
#VERSION:          0.4
#USAGE:            ./mysql_backup.sh
#DAILY CRON:
  # example cron for daily db backup @ 9:15 am
  # min  hr mday month wday command
  # 15   9  *    *     *    /Users/[your user name]/scripts/mysql_backup.sh

#RESTORE FROM BACKUP
  #$ gunzip < [backupfile.sql.gz] | mysql -u [uname] -p[pass] [dbname]

#==============================================================================
# CUSTOM SETTINGS
#==============================================================================

# directory to put the backup files
BACKUP_DIR=/Users/[your user name]/backup

# MYSQL Parameters
MYSQL_UNAME=root
MYSQL_PWORD=

# Don't backup databases with these names 
# Example: starts with mysql (^mysql) or ends with _schema (_schema$)
IGNORE_DB="(^mysql|_schema$)"

# include mysql and mysqldump binaries for cron bash user
PATH=$PATH:/usr/local/mysql/bin

# Number of days to keep backups
KEEP_BACKUPS_FOR=30 #days

#==============================================================================
# MAIN SCRIPT
#==============================================================================

function delete_old_backups()
{
  echo "Deleting $BACKUP_DIR/*.sql.gz older than $KEEP_BACKUPS_FOR days"
  find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +$KEEP_BACKUPS_FOR -exec rm {} \;
}

delete_old_backups

# Build Login String
mysql_login="-u $MYSQL_UNAME" 
if [ -n "$MYSQL_PWORD" ]; then
  mysql_login+=" -p$MYSQL_PWORD" 
fi

# build database list
show_databases="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'" 
database_list=$(mysql $mysql_login -e "$show_databases"|awk -F " " '{if (NR!=1) print $1}')

# YYYY-MM-DD
timestamp=$(date +%F)
echo "Filename Timestamp: $timestamp" 

# backup all MySQL databases
for database in $database_list; do
  backup_file="$BACKUP_DIR/$timestamp.$database.sql.gz" 
  echo "Backup $database to $backup_file" 
  mysqldump $mysql_login $database | gzip -9 > $backup_file
done

