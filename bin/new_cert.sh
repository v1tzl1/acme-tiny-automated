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



# Create private key
openssl genrsa -config ${CONFIG} > ${KEY_PATH}
if [ ! -f ${KEY_PATH} ]; then
    echo "Key file not created.";
    exit 1;
fi
chmod 0600 ${KEY_PATH};

# Create CSR
openssl req -config ${CONFIG} -key ${KEY_PATH} -new -out ${CSR_PATH}
if [ ! -f ${CSR_PATH} ]; then
    echo "CSR file ${CSR_PATH} not created.";
    exit 1;
fi
chmod 0644 ${CSR_PATH};

# Run acme-tiny as user $USER_ACME
(exec sudo -u ${USER_ACME} run-acme-tiny.sh ${DOMAIN} ${SUFFIX})

if [ ! -f ${CRT_PATH} ]; then
    echo "CRT file ${CRT_PATH} not created.";
    exit 1;
fi
chmod 0600 ${CRT_PATH};

if [ ! -f ${PEM_PATH} ]; then
    echo "PEM file ${PEM_PATH} not created.";
    exit 1;
fi
chmod 0600 ${PEM_PATH};

# Check that provate key and obtained certificate have the same modulus, i.e. they belong together
if [[ `openssl x509 -noout -modulus -in ${CRT_PATH} | openssl md5` != `openssl rsa -noout -modulus -in ${KEY_PATH} | openssl md5` ]]; then
    echo "Private key and certificate do not belong together (modulus mismatch).";
    exit 1;
fi

# Move them to storage area and set file permission again (better be safe than sorry)
mv ${KEY_PATH} ${KEY_STOR_PATH};
chown ${USER_GEN}:${USER_GEN} ${KEY_STOR_PATH};
chmod 0600 ${KEY_STOR_PATH};

mv ${CSR_PATH} ${CSR_STOR_PATH};
mv ${CRT_PATH} ${CRT_STOR_PATH};
mv ${PEM_PATH} ${PEM_STOR_PATH};

# Update symlinks
cd "${DIR_CERTS}/live"

for ext in "key" "crt" "csr" "pem"
do
    if [ -e "${DOMAIN}.${ext}" ]; then
        if [ -L "${DOMAIN}.${ext}" ]; then
            rm "${DOMAIN}.${ext}";
        else
            echo "File ${DIR_CERTS}/live/${DOMAIN}.${ext} exists and is NOT a symlink. Abort to make sure I am not deleting files.";
            exit 1;
        fi
    fi
    ln -s "../storage/${YEAR}/${DOMAIN}-${SUFFIX}.${ext}" "${DOMAIN}.${ext}";
done

# Update services
(exec sudo nohup "${DIR_BIN}/services-update.sh")

exit 0
