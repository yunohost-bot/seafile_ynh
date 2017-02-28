#!/bin/bash 

seafile_version=6.0.8

## Adapt md5sum while you update app
x86_64sum="353de460ed8a08f176103e96f1384ff3"
i386sum="9a4bc83576ec74b46a907ca081d4914d"
armsum="d7a0bd1d0a3948e1d3bc175e6d1ddca8"

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

CHECK_VAR () {	# Vérifie que la variable n'est pas vide.
# $1 = Variable à vérifier
# $2 = Texte à afficher en cas d'erreur
	test -n "$1" || (echo "$2" >&2 && false)
}

# Ignore the yunohost-cli log to prevent errors with conditionals commands
# usage: NO_LOG COMMAND
# Simply duplicate the log, execute the yunohost command and replace the log without the result of this command
# It's a very badly hack...
# Petite copie perso à mon usage ;)
NO_LOG () {
  ynh_cli_log=/var/log/yunohost/yunohost-cli.log
  sudo cp -a ${ynh_cli_log} ${ynh_cli_log}-move
  eval $@
  exit_code=$?
  sudo mv ${ynh_cli_log}-move ${ynh_cli_log}
  return $?
}

CHECK_PATH () {	# Vérifie la présence du / en début de path. Et son absence à la fin.
	if [ "${path:0:1}" != "/" ]; then    # Si le premier caractère n'est pas un /
		path="/$path"    # Ajoute un / en début de path
	fi
	if [ "${path:${#path}-1}" == "/" ] && [ ${#path} -gt 1 ]; then    # Si le dernier caractère est un / et que ce n'est pas le seul caractère.
		path="${path:0:${#path}-1}"	# Supprime le dernier caractère
	fi
}

FIND_PORT () {	# Cherche un port libre.
# $1 = Numéro de port pour débuter la recherche.
	port=$1
	while ! sudo yunohost app checkport $port ; do
		port=$((port+1))
	done
	CHECK_VAR "$port" "port empty"
}
