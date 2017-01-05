#!/bin/bash 

seafile_version=6.0.7

## Adapt md5sum while you update app
x86_64sum="4ca3c1fc93e5b786eb5d3509f4a3b01a"
i386sum="743565be00189698318c8def0fbdaac0"
armsum="ee3ef5330a51498faf861594e0fe744a"

init_script() {
    # Exit on command errors and treat unset variables as an error
    set -eu

    # Source YunoHost helpers
    source /usr/share/yunohost/helpers

    # Retrieve arguments
    app=$YNH_APP_INSTANCE_NAME
}

correct_path() {
    if [ "${path:0:1}" != "/" ] && [ ${#path} -gt 0 ]; then
        path="/$path"
    fi
    if [ "${path:${#path}-1}" == "/" ] && [ ${#path} -gt 1 ]; then
        path="${path:0:${#path}-1}"
    fi
}

set_configuration() {
    if [[ -e /var/www/$app ]]
    then
        final_path=/var/www/$app
        seafile_user=www-data
    elif [[ -e /opt/yunohost/$app ]]
    then
        final_path=/opt/yunohost/$app
        seafile_user=seafile
    else
        ynh_die "Error : can't find seafile path"
    fi
}

get_source() {
    if [[ $1 == 'arm' ]]
    then
        wget -q -O '/tmp/seafile_src.tar.gz' 'https://github.com/haiwen/seafile-rpi/releases/download/v'$2'/seafile-server_'$2'_stable_pi.tar.gz'
        md5sum=$armsum
    elif [[ $1 == 'x86-64' ]]
    then
        wget -q -O '/tmp/seafile_src.tar.gz' 'https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_'$2'_x86-64.tar.gz'
        md5sum=$x86_64sum
    else
        wget -q -O '/tmp/seafile_src.tar.gz' 'https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_'$2'_i386.tar.gz'
        md5sum=$i386sum
    fi

    if [[ ! -e '/tmp/seafile_src.tar.gz' ]] || [[ $(md5sum '/tmp/seafile_src.tar.gz' | cut -d' ' -f1) != $md5sum ]]
    then
        ynh_die "Error : can't get seafile source"
    fi
}