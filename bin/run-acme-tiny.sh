#!/bin/bash

source `dirname $0`/../config.sh

if [[ $USER != ${USER_ACME} ]]; then
    echo "This script is only supposed to be run by the user ${USER_ACME}";
    exit 1;
fi

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` domain suffix\nWill create a certificate based on the CSR ${DIR_CERTS}/csr/<domain>-<suffix>.csr"
    exit 1;
fi

DOMAIN=$1
SUFFIX=$2

CSR_PATH="${DIR_CERTS}/tmp/csr/${DOMAIN}-${SUFFIX}.csr"
CRT_PATH="${DIR_CERTS}/tmp/crt/${DOMAIN}-${SUFFIX}.crt"
PEM_PATH="${DIR_CERTS}/tmp/crt/${DOMAIN}-${SUFFIX}.pem"

if [ ! -f ${CSR_PATH} ]; then
    echo "Could not find CSR file ${CSR_PATH}";
    exit 1;
fi

if [ ! -f ${ACME_TINY_PATH} ]; then
    echo "Could not find acme-tiny python file at ${ACME_TINY_PATH}";
    exit 1;
fi

# Obtain certificate
( exec nohub python ${ACME_TINY_PATH} --account-key "${DIR_CERTS}/${ACCOUNT_KEY}" --account-email "${ACCOUNT_CONTACT}" --csr "${CSR_PATH}" --acme-dir "${DIR_CHALLENGE}" > ${CRT_PATH} )

if [ ! -f ${CRT_PATH} ]; then
    echo "Certificate ${CRT_PATH} was not created.";
    exit 1;
fi

# Create PEM file with intermediate certificate
CHAIN_PATH="${DIR_CERTS}/chain.pem"
if [ ! -f ${CHAIN_PATH} ]; then
    wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > ${CHAIN_PATH};
fi

if [ ! -f ${CHAIN_PATH} ]; then
    echo "Cannot find intermediate certificate and download failed.";
    exit 1;
fi
cat ${CSR_PATH} ${CHAIN_PATH} > ${PEM_PATH}
