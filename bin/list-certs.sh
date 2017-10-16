#!/bin/bash

source `dirname $0`/../config.sh

#if [[ $USER != ${USER_CRON} ]]; then
#    echo "This script is only supposed to be run by the user ${USER_CRON}";
#    exit 1;
#fi

cd "${DIR_CERTS}/configs"
for config in *.cnf
do
	DOMAIN="${config%.cnf}"
	VALID_DATE=$(date --date="$(openssl x509 -enddate -noout -in "../live/${DOMAIN}.crt"|cut -d= -f 2)" "+%d.%m.%Y %H:%M")
	#echo "checking domain ${file%.cnf}: `openssl x509 -enddate -noout -in "../live/${config%.cnf}.crt"`"
	#$(date --date="$(openssl x509 -enddate -noout -in "$pem"|cut -d= -f 2)" --iso-8601)"

	openssl x509 -checkend 0 -noout -in "../live/${DOMAIN}.crt";
	VALID_NOW="$?"
	openssl x509 -checkend $((21*24*3600)) -noout -in "../live/${DOMAIN}.crt";
	VALID_FUTURE="$?"

	if [ ${VALID_FUTURE} -eq 0 ]; then
		# green
		COL_STR="\e[32m";
	elif [ ${VALID_NOW} -eq 0 ]; then
		# yellow
		COL_STR="\e[33m";
	else
		# red
		COL_STR="\e[31m";
	fi

	echo -e "${DOMAIN}: ${COL_STR}${VALID_DATE}\e[0m"

done
