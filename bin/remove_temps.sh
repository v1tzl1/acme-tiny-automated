#!/bin/bash

source `dirname $0`/../config.sh

cd "${DIR_CERTS}/tmp";

for folder in "key" "csr" "crt" "pem" "logs"
do
    for file in ${folder}/*
    do
        echo 'rm "${folder}/${file}"'
        rm "${folder}/${file}"
    done
done
