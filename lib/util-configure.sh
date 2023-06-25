#!/bin/bash

function configureDNS()
{
    export ETC_HOSTS_SRC=/etc/hosts
    export ETC_HOSTS_DST=${HOME}/etc-hosts
    export TARGET_NAME=${1}
    export TARGET_DOMAIN=${2}
    export TARGET_HOST=${3}

    if [[ ${TARGET_NAME} == "" ]]; then
        TARGET_NAME="company"
    fi

    if [[ ${TARGET_DOMAIN} == "" ]]; then
        TARGET_HOST="undefined.local"
    fi

    if [[ ${TARGET_HOST} == "" ]]; then
        TARGET_HOST="127.0.0.1"
    fi

    //if [[ TARGET_APP_LIST=(db fil acl msg fil agt) ]]; 


    cat ${ETC_HOSTS_SRC} > ${ETC_HOSTS_DST}

    
    DNS_PREFIX=development-company-erp
    TARGET_ENV_LIST=(development staging production)   
    TARGET_APP_LIST=(db fil acl msg fil agt)
    LINES=()
    echo "" >> ${ETC_HOSTS_DST}
    echo "# ${TARGET_NAME}" >> ${ETC_HOSTS_DST}
    for TARGET_ENV in "${TARGET_ENV_LIST[@]}" do
        echo "" >> ${ETC_HOSTS_DST}
        echo "# ${TARGET_NAME}" >> ${ETC_HOSTS_DST}
        for TARGET_APP in "${TARGET_APP_LIST[@]}" do
            LINE=${TARGET_ENV}-${TARGET}-${TARGET_APP}.${TARGET_DOMAIN}
            echo $(sed -i "s/${LINE}//g" ${ETC_HOSTS_DST})&>/dev/null
        done
    done   
}