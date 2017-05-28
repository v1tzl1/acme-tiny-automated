#!/bin/bash

cd `dirname $0`

cp config.sh.example config.sh;
nano config.sh

source config.sh

##### Create users
groupadd -r ${GROUP_COMMON};
useradd --shell /bin/false --system ${USER_CRON};
useradd --shell /bin/false --system -U -G${GROUP_COMMON} ${USER_GEN};
useradd --shell /bin/false --system -U -G${GROUP_COMMON} ${USER_ACME};

##### Create folders
mkdir ${DIR_CERTS}
cd ${DIR_CERTS}

mkdir live
chown ${USER_GEN}:${USER_GEN} live
chmod 0750 live

mkdir storage
chown ${USER_GEN}:${USER_GEN} storage
chmod 0750 storage

mkdir configs
chown root:${USER_GEN} configs
chmod 0750 configs

mkdir tmp
chmod 0755 tmp

cd tmp

mkdir key
chown ${USER_GEN}:${USER_GEN} key
chmod 0700 key

mkdir csr
chown ${USER_GEN}:${GROUP_COMMON} csr
chmod 0750 csr

mkdir crt
chown ${USER_GEN}:${GROUP_COMMON} crt
chmod 0770 crt

mkdir logs
chown ${USER_GEN}:${GROUP_COMMON} logs
chmod 0770 crt

mkdir ${DIR_CHALLENGE}
chown ${USER_ACME}:${USER_ACME} ${DIR_CHALLENGE}
chmod 0755 ${DIR_CHALLENGE}

##### Create letsencrypt account
cd ${DIR_CERTS}
openssl genrsa 4096 > ${ACCOUNT_KEY}
chown ${USER_GEN}:${USER_GEN} ${ACCOUNT_KEY}
chmod 0600 ${ACCOUNT_KEY}

##### Copy files
mkdir -p ${DIR_BIN}

TMP=`dirname ${ACME_TINY_PATH}`;
TMP2=`dirname ${TMP}`;
mkdir -p ${TMP2};
cd ${TMP2};
git clone https://github.com/v1tzl1/acme-tiny.git;

if [ ! -f ${ACME_TINY_PATH} ]; then echo "Acme-tiny path incorrect: ${ACME_TINY_PATH}"; fi

cp config.sh ${DIR_CERTS}/

cp example.cnf "${DIR_CERTS}/configs/example.cnf_"
chown root:${USER_GEN} "${DIR_CERTS}/configs/example.cnf_"
chmod 0640 "${DIR_CERTS}/configs/example.cnf_"

cp bin/update-certs.sh ${DIR_BIN}/
chown ${USER_CRON}:${USER_CRON} "${DIR_BIN}/update-certs.sh"
chmod 0744 "${DIR_BIN}/update-certs.sh"

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

echo "Defaults:${USERR_CRON} !requiretty" > /etc/sudoers.d/letsencrypt-acme-tiny-automated
echo "Defaults:${USERR_GEN} !requiretty" >> /etc/sudoers.d/letsencrypt-acme-tiny-automated
echo "${USER_CRON} ALL=(${USER_GEN}) NOPASSWD: ${DIR_BIN}/new_certs.sh" >> /etc/sudoers.d/letsencrypt-acme-tiny-automated
echo "${USER_CRON} ALL=(root) NOPASSWD: ${DIR_BIN}/services-update.sh" >> /etc/sudoers.d/letsencrypt-acme-tiny-automated
echo "${USER_GEN} ALL=(${USER_ACME}) NOPASSWD: ${DIR_BIN}/run-acme-tiny.sh" >> /etc/sudoers.d/letsencrypt-acme-tiny-automated

echo "Cross-check and update sudoers file with"
echo "visudo -f /etc/sudoers.d/letsencrypt-acme-tiny-automated"
