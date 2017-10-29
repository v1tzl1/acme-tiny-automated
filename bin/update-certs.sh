#!/bin/bash

source `dirname $0`/../config.sh

if [[ $USER != ${USER_CRON} ]]; then
    echo "This script is only supposed to be run by the user ${USER_CRON}";
    exit 1;
fi

cd "${DIR_CERTS}/configs"
for config in *.cnf
do
	DOMAIN="${config%.cnf}"

	# Is domain still valid in the next 20 days
	openssl x509 -checkend $((20*24*3600)) -noout -in "../live/${DOMAIN}.crt";
	EXPIRE_SOON="$?"

	if [ ${EXPIRE_SOON} -eq 1 ]; then
		echo "Renewing ${DOMAIN}"
		echo "ECHO: sudo -u ${USER_GEN} ${DIR_CERTS}/bin/new_cert.sh ${DOMAIN}"
	else
		echo "Domain ${DOMAIN} is still valid"
	fi

done
