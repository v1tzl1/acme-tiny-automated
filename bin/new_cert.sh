#!/bin/bash

source config.sh

if [[ $USER != ${USER_GEN} ]]; then
    echo "This script is only supposed to be run by the user ${USER_GEN}";
    exit 1;
fi

if [ $# -ne 1 ]; then
    echo "Usage: `basename $0` domain\n\nThere must be an openssl config file in ${DIR_CERTS}/configs/<domain>.cnf"
    exit 1;
fi

DOMAIN=$1
CONFIG="${DIR_CERTS}/configs/${DOMAIN}.cnf"

if [ ! -f ${CONFIG} ]; then
    echo "Could not find configuration file ${CONFIG}";
    exit 1;
fi

SUFFIX=`date "+%Y-%m-%d-%H-%M"`
YEAR=`date "+%Y"`

KEY_PATH="${DIR_CERTS}/tmp/key/${DOMAIN}-${SUFFIX}.key"
CSR_PATH="${DIR_CERTS}/tmp/csr/${DOMAIN}-${SUFFIX}.csr"
CRT_PATH="${DIR_CERTS}/tmp/crt/${DOMAIN}-${SUFFIX}.crt"
PEM_PATH="${DIR_CERTS}/tmp/crt/${DOMAIN}-${SUFFIX}.pem"

if [ ! -d "${DIR_CERTS}/storage/${YEAR}" ]; then
    mkdir "${DIR_CERTS}/storage/${YEAR}";
    chmod 0755 "${DIR_CERTS}/storage/${YEAR}";
fi

KEY_STOR_PATH="${DIR_CERTS}/storage/${YEAR}/${DOMAIN}-${SUFFIX}.key"
CSR_STOR_PATH="${DIR_CERTS}/storage/${YEAR}/${DOMAIN}-${SUFFIX}.csr"
CRT_STOR_PATH="${DIR_CERTS}/storage/${YEAR}/${DOMAIN}-${SUFFIX}.crt"
PEM_STOR_PATH="${DIR_CERTS}/storage/${YEAR}/${DOMAIN}-${SUFFIX}.pem"

LOGFILE="${DIR_CERTS}/tmp/logs/${DOMAIN}-${SUFFIX}.log"

touch ${LOGFILE};
chown ${USER_GEN}:${GROUP_COMMON} ${LOGFILE};
chmod 0660 ${LOGFILE};

# Create private key
echo "openssl genrsa 4096 > ${KEY_PATH}" >> ${LOGFILE}
openssl genrsa 4096 > ${KEY_PATH} 2>> ${LOGFILE}
if [ ! -f ${KEY_PATH} ]; then
    echo "Key file not created.";
    exit 1;
fi
chmod 0600 ${KEY_PATH} >> ${LOGFILE} 2>&1;

# Create CSR
echo "openssl req -config ${CONFIG} -key ${KEY_PATH} -new -out ${CSR_PATH}" >> ${LOGFILE}
openssl req -config ${CONFIG} -key ${KEY_PATH} -new -out ${CSR_PATH} 2>> ${LOGFILE}
if [ ! -f ${CSR_PATH} ]; then
    echo "CSR file ${CSR_PATH} not created.";
    exit 1;
fi
chmod 0644 ${CSR_PATH} >> ${LOGFILE} 2>&1;

# Create CRT and PEM files, so the have the right ownership
touch ${CRT_PATH}
touch ${PEM_PATH}
chown ${USER_GEN}:${GROUP_COMMON} ${CRT_PATH} >> ${LOGFILE} 2>&1;
chown ${USER_GEN}:${GROUP_COMMON} ${PEM_PATH} >> ${LOGFILE} 2>&1;
chmod 0664 ${CRT_PATH} >> ${LOGFILE} 2>&1;
chmod 0664 ${PEM_PATH} >> ${LOGFILE} 2>&1;

# Run acme-tiny as user $USER_ACME
(exec sudo -u ${USER_ACME} "${DIR_BIN}/run-acme-tiny.sh" ${DOMAIN} ${SUFFIX} >> ${LOGFILE} 2>&1)

if [ ! -f ${CRT_PATH} ]; then
    echo "CRT file ${CRT_PATH} not created.";
    exit 1;
fi

if [ ! -f ${PEM_PATH} ]; then
    echo "PEM file ${PEM_PATH} not created.";
    exit 1;
fi

# Check that provate key and obtained certificate have the same modulus, i.e. they belong together
if [[ `openssl x509 -noout -modulus -in ${CRT_PATH} | openssl md5` != `openssl rsa -noout -modulus -in ${KEY_PATH} | openssl md5` ]]; then
    echo "Private key and certificate do not belong together (modulus mismatch).";
    exit 1;
else
    echo "Moduli of ${CRT_PATH} and ${KEY_PATH} agree" >> ${LOGFILE}
fi

# Move them to storage area and set file permission again (better be safe than sorry)
mv ${KEY_PATH} ${KEY_STOR_PATH} >> ${LOGFILE} 2>&1;
chown ${USER_GEN}:${USER_GEN} ${KEY_STOR_PATH} >> ${LOGFILE} 2>&1;
chmod 0600 ${KEY_STOR_PATH} >> ${LOGFILE} 2>&1;

mv ${CSR_PATH} ${CSR_STOR_PATH} >> ${LOGFILE} 2>&1;
mv ${CRT_PATH} ${CRT_STOR_PATH} >> ${LOGFILE} 2>&1;
mv ${PEM_PATH} ${PEM_STOR_PATH} >> ${LOGFILE} 2>&1;

# Update symlinks
cd "${DIR_CERTS}/live" >> ${LOGFILE} 2>&1

for ext in "key" "crt" "csr" "pem"
do
    if [ -e "${DOMAIN}.${ext}" ]; then
        if [ -L "${DOMAIN}.${ext}" ]; then
            echo 'rm "${DOMAIN}.${ext}"' >> ${LOGFILE} 2>&1
            rm "${DOMAIN}.${ext}";
        else
            echo "File ${DIR_CERTS}/live/${DOMAIN}.${ext} exists and is NOT a symlink. Abort to make sure I am not deleting files.";
            echo "File ${DIR_CERTS}/live/${DOMAIN}.${ext} exists and is NOT a symlink. Abort to make sure I am not deleting files." >> ${LOGFILE};
            exit 1;
        fi
    fi
    echo 'ln -s "../storage/${YEAR}/${DOMAIN}-${SUFFIX}.${ext}" "${DOMAIN}.${ext}"' >> ${LOGFILE}
    ln -s "../storage/${YEAR}/${DOMAIN}-${SUFFIX}.${ext}" "${DOMAIN}.${ext}" >> ${LOGFILE} 2>&1;
done

# Update services
echo "Updating services" >> ${LOGFILE}
(exec nohup sudo "${DIR_BIN}/services-update.sh" >> ${LOGFILE} 2>&1)
echo "Services updated" >> ${LOGFILE}

exit 0
