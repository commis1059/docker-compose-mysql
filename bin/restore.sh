#!/bin/sh

MYSQL_SERVICE_NAME=mysql

usage() {
  echo 'usage: restore.sh'
  exit 1
}


echo 'Please select the file number you want to restore\n'
files=(`ls backup_data | nl -s : -v 0`)
for file in ${files[@]}; do
  echo ${file}
done


read number
expr ${number} + 1 > /dev/null 2>&1
if [ $? -gt 1 ]; then
  echo 'The file number must be a number'
  exit 1
fi
if [ ${number} -ge ${#files[@]} ]; then
  echo 'The file not exists'
  exit 1
fi


file=`echo ${files[${number}]} | tr : '\n' | tail -n 1`
export BACKUP_FILE=${file}
export TARGET_VOLUME=`basename ${BACKUP_FILE} | sed -E s/_[^_]+\.tar\.gz$//`


if [ `docker-compose ps ${MYSQL_SERVICE_NAME} | tail -n 1 | sed -E 's/ +/ /g' | cut -d ' ' -f4` = 'Up' ]; then
  docker-compose stop ${MYSQL_SERVICE_NAME}
  mysql_started='true'
fi


echo 'Restore start'
docker-compose -f etc/restore.yml run --rm restore > /dev/null
if [ $? -eq 0 ]; then
  echo "Restore to ${TARGET_VOLUME}"
else
  echo 'Failed'
fi


if [ -n "${mysql_started}" ]; then
  docker-compose start ${MYSQL_SERVICE_NAME}
fi