#!/bin/bash 

set_configuration() {
    if [[ -e /var/www/$app ]]
    then
        final_path=/var/www/$app
        seafile_user=www-data
    elif [[ -e /opt/yunohost/$app ]]
        final_path=/opt/yunohost/$app
        seafile_user=seafile
    else
        ynh_die "Error : can't find seafile path"
    fi
}


get_source() {
    if [[ $1 == 'arm' ]]
    then
        wget -O '/tmp/seafile_src.tar.gz' 'https://github.com/haiwen/seafile-rpi/releases/download/v'$2'/seafile-server'$1'_stable_pi.tar.gz'
    else
        wget -O '/tmp/seafile_src.tar.gz' 'https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_'$1'_'$2'.tar.gz'
    fi

    if [[ ! -e '/tmp/seafile_src.tar.gz' ]]
    then
        ynh_die "Error : can't get seafile source"
    fi
}