#!/bin/sh

MYSQL_SERVICE_NAME=mysql

usage() {
  echo 'usage: backup.sh [-t tag_name]'
  exit 1
}


while getopts :t: opt; do
  case ${opt} in
    t)  tag=${OPTARG};;

    :|\?)  usage;;
  esac
done
shift `expr ${OPTIND} - 1`


echo 'Please select the volume number you want to backup\n'
volumes=(`docker volume ls -q | nl -s : -v 0`)
for volume in ${volumes[@]}; do
  echo ${volume}
done


read number
expr ${number} + 1 > /dev/null 2>&1
if [ $? -gt 1 ]; then
  echo 'The volume number must be a number'
  exit 1
fi
if [ ${number} -ge ${#volumes[@]} ]; then
  echo 'The volume not exists'
  exit 1
fi


volume=`echo ${volumes[${number}]} | tr : '\n' | tail -n 1`
if [ -z ${tag} ]; then
  tag=`date '+%Y%m%d%H%M%S'`
fi
export TARGET_VOLUME=${volume}
export TAG=${tag}
export BACKUP_DIR=backup_data


if [ `docker-compose ps ${MYSQL_SERVICE_NAME} | tail -n 1 | sed -E 's/ +/ /g' | cut -d ' ' -f4` = 'Up' ]; then
  docker-compose stop ${MYSQL_SERVICE_NAME}
  mysql_started='true'
fi


echo 'Backup start'
docker-compose -f etc/backup.yml run --rm backup > /dev/null
if [ $? -eq 0 -a -s backup_data/${TARGET_VOLUME}_${TAG}.tar.gz ]; then
  echo "Backup to backup_data/${TARGET_VOLUME}_${TAG}.tar.gz"
else
  echo 'Failed'
  exit 1
fi


if [ -n "${mysql_started}" ]; then
  docker-compose start ${MYSQL_SERVICE_NAME}
fi