#!/bin/bash

cd `dirname $0`

if [ -f config.sh ]; then
	source config.sh
else
	echo "Cannot find a configuration file (config.sh) in `dirname $0`";
	exit 1;
fi

cp bin/update-certs.sh ${DIR_BIN}/
chown ${USER_CRON}:${USER_CRON} "${DIR_BIN}/update-certs.sh"
chmod 0744 "${DIR_BIN}/update-certs.sh"

cp bin/list-certs.sh ${DIR_BIN}/
chown ${USER_CRON}:${USER_CRON} "${DIR_BIN}/list-certs.sh"
chmod 0744 "${DIR_BIN}/list-certs.sh"

cp bin/new_cert.sh ${DIR_BIN}/
chown ${USER_GEN}:${USER_CRON} "${DIR_BIN}/new_cert.sh"
chmod 0744 "${DIR_BIN}/new_cert.sh"

cp bin/run-acme-tiny.sh ${DIR_BIN}/
chown ${USER_ACME}:${USER_ACME} "${DIR_BIN}/run-acme-tiny.sh"
chmod 0744 "${DIR_BIN}/run-acme-tiny.sh"

cp bin/services-update.sh ${DIR_BIN}/
chown root:${USER_GEN} "${DIR_BIN}/services-update.sh"
chmod 0744 "${DIR_BIN}/services-update.sh"

cp bin/remove_temps.sh ${DIR_BIN}/
chown root:root "${DIR_BIN}/remove_temps.sh"
chmod 0744 "${DIR_BIN}/remove_temps.sh"

