#!/bin/bash

source `dirname $0`/../config.sh

cd "${DIR_CERTS}/tmp";

for folder in "key" "csr" "crt" "pem" "logs"
do
    for file in ${folder}/*;
    do
        if [ -f ${file} ]; then
            echo "rm ${file}"
            rm ${file}
        fi
    done
done
