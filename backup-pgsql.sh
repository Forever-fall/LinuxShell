#! /bin/bash

#修改db_user和db_name
pg_dump -h localhost -U db_user db_name> /var/lib/pgsql/pgsql_backup/db_name_backup_$(date +%Y%m%d_%H%M%S).sql

sleep 5

#删除三天前备份的sql文件，只保留三天以内的
find /var/lib/pgsql/pgsql_backup/*.sql -mtime 3 -exec rm -rf {} \;
