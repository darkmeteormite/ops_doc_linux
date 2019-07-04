#!/bin/sh

#######配置####

#全量备份时间  每周日 凌晨 4 点
#增量备份时间  每五分钟一次
FULL_DATE='0'
FULL_TIME='04'

ARCHIVE_DIR="/data/archive/"
PG_RMAN='/usr/local/pgsql/bin/pg_rman'
CLEANUP='/usr/local/pgsql/bin/pg_archivecleanup'
BACKUP_DIR='/backup/pg_rman'
DATA_DIR='/data/pgsql'

CURRENT_DATE=`date +%w`
CURRENT_TIME=`date +%H`

#增量备份
function inc_backup ()
{
                #增量备份
                ${PG_RMAN} backup --backup-mode=archive -P -Z -B ${BACKUP_DIR} -D ${DATA_DIR} -U postgres -p 3433

                #CRC校验
                ${PG_RMAN} validate -B ${BACKUP_DIR} -D ${DATA_DIR} -U postgres

}

#全量备份
function full_backup ()
{
		#全量备份
		${PG_RMAN} backup --backup-mode=full --progress -B ${BACKUP_DIR} -D ${DATA_DIR} -p 3433 -U postgres 

		#CRC校验
		${PG_RMAN} validate -B ${BACKUP_DIR} -D ${DATA_DIR} -U postgres
		
		#删除上周备份
		DEL_TIME=`${PG_RMAN} show -B ${BACKUP_DIR}|awk '{if($5=="FULL") {print $1" "$2}}'|head -1`
                ${PG_RMAN} delete "${DEL_TIME}"  -B ${BACKUP_DIR}

		#清除已删除的备份信息
		${PG_RMAN} purge -B ${BACKUP_DIR}

}


#清理归档日志
function clean_archive ()
{
		#清理.bash_history,有时系统会在这里生成history
		if [ -f "${ARCHIVE_DIR}.bash_history" ];then
			rm -f ${ARCHIVE_DIR}.bash_history
		fi

		#清理1小时之前的归档日志
		xlog=`/bin/find ${ARCHIVE_DIR} -type f -cmin +60|grep -v backup|sort|tail -n 1`
		if [ "A${xlog}" != "A" ];then
        		log_file=`basename ${xlog}`
        		${CLEANUP} -d ${ARCHIVE_DIR} ${log_file}
		fi

}

#检查是否正在CRC校验
function check ()
{
                ischeck=`ps -ef|grep pg_rman|grep -c validate`
                if [ ${ischeck} -ge 1 ];then
                        exit;
                fi
}

if [ ${CURRENT_DATE} == ${FULL_DATE} ];then
	if [ ${CURRENT_TIME} == ${FULL_TIME} ];then
	        FLAG_DATE=`${PG_RMAN} show -B ${BACKUP_DIR} |awk '{if($5=="FULL") {print $1" "$2}}'|head -1|awk -F":" '{print $1}'`
                CURRENT_DATE=`date +"%Y-%m-%d %H"`
		#如果已经做完全量备份，立即退出程序
                if [ "${FLAG_DATE}" == "${CURRENT_DATE}" ];then
                        exit
                fi
		check
		full_backup
	else	
		check
		inc_backup
		clean_archive
	fi
else
		check
		inc_backup
		clean_archive

fi





