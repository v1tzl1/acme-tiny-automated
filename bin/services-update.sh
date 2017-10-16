#!/bin/bash

if [[ $USER != "root" ]]; then
    echo "This script is only supposed to be run by root";
    exit 1;
fi

/etc/init.d/nginx reload
/etc/init.d/postfix reload
/etc/init.d/dovecot reload
