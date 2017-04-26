#!/bin/bash 

seafile_version=6.0.9

## Adapt md5sum while you update app
x86_64sum="8d1547c51feecaff757eb64381ce154c"
i386sum="8a0b9e08d9c80790752b435c3e148328"
armsum="15ca4b69585a990e00474e4cfc4be9eb"

init_script() {
    # Exit on command errors and treat unset variables as an error
    set -eu

    # Source YunoHost helpers
    source /usr/share/yunohost/helpers

    # Retrieve arguments
    app=$YNH_APP_INSTANCE_NAME
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
    if [[ $1 == 'rpi' ]]
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

CHECK_VAR () {	# Vérifie que la variable n'est pas vide.
# $1 = Variable à vérifier
# $2 = Texte à afficher en cas d'erreur
	test -n "$1" || (echo "$2" >&2 && false)
}

CHECK_PATH () {	# Vérifie la présence du / en début de path. Et son absence à la fin.
	if [ "${path:0:1}" != "/" ]; then    # Si le premier caractère n'est pas un /
		path="/$path"    # Ajoute un / en début de path
	fi
	if [ "${path:${#path}-1}" == "/" ] && [ ${#path} -gt 1 ]; then    # Si le dernier caractère est un / et que ce n'est pas le seul caractère.
		path="${path:0:${#path}-1}"	# Supprime le dernier caractère
	fi
}

# Find a free port and return it
#
# example: port=$(ynh_find_port 8080)
#
# usage: ynh_find_port begin_port
# | arg: begin_port - port to start to search
ynh_find_port () {
	port=$1
	test -n "$port" || ynh_die "The argument of ynh_find_port must be a valid port."
	while netcat -z 127.0.0.1 $port       # Check if the port is free
	do
		port=$((port+1))	# Else, pass to next port
	done
	echo $port
}
