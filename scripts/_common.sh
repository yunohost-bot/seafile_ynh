#!/bin/bash 

# Retrieve arguments
app=$YNH_APP_INSTANCE_NAME

## Adapt sha256sum while you update app
x86_64sum="166a022786c8bb85d5890741f9632f10df3ba299736c59576ab1f6e4f6597ac8"
i386sum="4439e13211a4c0dd7831d728fc50371d9be0e31dfa344b1c951de90b42afe0bf"
armsum="e23af4882e8b20c8ded8c052e9863a52dbb685f16deff0322e21d6e9ded35b56"

# Detect the system architecture to download the right tarball
# NOTE: `uname -m` is more accurate and universal than `arch`
# See https://en.wikipedia.org/wiki/Uname
if [ -n "$(uname -m | grep 64)" ]; then
	architecture="x86-64"
elif [ -n "$(uname -m | grep 86)" ]; then
	architecture="i386"
elif [ -n "$(uname -m | grep arm)" ]; then
	architecture="arm"
else
	ynh_die "Unable to detect your achitecture, please open a bug describing \
        your hardware and the result of the command \"uname -m\"." 1
fi

get_app_version_from_json() {
   manifest_path="../manifest.json"
    if [ ! -e "$manifest_path" ]; then
    	manifest_path="../settings/manifest.json"	# Into the restore script, the manifest is not at the same place
    fi
    echo $(grep '\"version\": ' "$manifest_path" | cut -d '"' -f 4)	# Retrieve the version number in the manifest file.
}
seafile_version=$(get_app_version_from_json)

get_configuration() {
	final_path=$(ynh_app_setting_get $app final_path)
	seafile_user=$(ynh_app_setting_get $app seafile_user)
	
	if [[ -z $final_path ]] || [[ -z $seafile_user ]]
	then
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
		ynh_app_setting_set $app final_path $final_path
		ynh_app_setting_set $app seafile_user $seafile_user
    fi
}

set_path_2() {
	if [[ $path == '/' ]]
	then
		path2=$path
	else
		path2=$path'/'
	fi
}

config_nginx() {


	# In the 3.x seafile version package the seahub_port and fileserver_port wasn't saved in the settings. If the settings is empty we try to get it and save in the settings

	if [[ -z $seahub_port ]] || [[ -z $fileserver_port ]]
	then
		seahub_port=$(head -n 20 /etc/nginx/conf.d/$domain.d/seafile.conf | grep -E "fastcgi_pass.*127.0.0.1:" | cut -d':' -f2 | cut -d';' -f1)
		fileserver_port=$(head -n 50 /etc/nginx/conf.d/$domain.d/seafile.conf | grep -E "proxy_pass.*127.0.0.1:" | cut -d':' -f3 | cut -d';' -f1 | cut -d'/' -f1)

		ynh_app_setting_set $app seahub_port $seahub_port
		ynh_app_setting_set $app fileserver_port $fileserver_port
	fi

	ynh_replace_string PATHTOCHANGE1 $path ../conf/nginx.conf
	ynh_replace_string PATHTOCHANGE2 $path2 ../conf/nginx.conf
	ynh_replace_string ALIASTOCHANGE $final_path/ ../conf/nginx.conf
	ynh_replace_string SEAHUB_PORT $seahub_port ../conf/nginx.conf
	ynh_replace_string SEAFILE_FILESERVER_PORT $fileserver_port ../conf/nginx.conf
	ynh_replace_string WEBDAV_PORT $webdav_port ../conf/nginx.conf
	cp ../conf/nginx.conf /etc/nginx/conf.d/$domain.d/seafile.conf
	
	systemctl reload nginx.service
}

get_source() {
    if [[ $1 == 'arm' ]]
    then
        wget -q -O '/tmp/seafile_src.tar.gz' 'https://github.com/haiwen/seafile-rpi/releases/download/v'$2'/seafile-server_'$2'_stable_pi.tar.gz'
        sha256sum=$armsum
    elif [[ $1 == 'x86-64' ]]
    then
        wget -q -O '/tmp/seafile_src.tar.gz' 'https://download.seadrive.org/seafile-server_'$2'_x86-64.tar.gz'
        sha256sum=$x86_64sum
    else
        wget -q -O '/tmp/seafile_src.tar.gz' 'https://download.seadrive.org/seafile-server_'$2'_i386.tar.gz'
        sha256sum=$i386sum
    fi

    if [[ ! -e '/tmp/seafile_src.tar.gz' ]] || [[ $(sha256sum '/tmp/seafile_src.tar.gz' | cut -d' ' -f1) != $sha256sum ]]
    then
        ynh_die "Error : can't get seafile source"
    fi
}

extract_source() {
	mkdir -p $final_path/seafile-server-$seafile_version
	tar xzf '/tmp/seafile_src.tar.gz'
	mv seafile-server-$seafile_version/* $final_path/seafile-server-$seafile_version
	mv '/tmp/seafile_src.tar.gz' $final_path/installed/seafile-server_${seafile_version}.tar.gz
	
	local old_dir=$(pwd)
    (cd "$final_path/seafile-server-$seafile_version" && patch -p1 < $YNH_CWD/../sources/sso_auth.patch) || ynh_die "Unable to apply patches"
    cd $old_dir
}

install_dependance() {
	ynh_install_app_dependencies python2.7 python-pip python-setuptools python-simplejson python-imaging python-mysqldb python-flup expect python-requests python-dev
	pip install pillow moviepy
}

ynh_clean_setup () {
	pkill -f seafile-controller
	pkill -f seaf-server
	pkill -f ccnet-server
	pkill -f "seahub"
}


# Implement PR : https://github.com/YunoHost/yunohost/pull/392

# Use logrotate to manage the logfile
#
# usage: ynh_use_logrotate [logfile] [--non-append]
# | arg: logfile - absolute path of logfile
# | option: --non-append - Replace the config file instead of appending this new config.
#
# If no argument provided, a standard directory will be use. /var/log/${app}
# You can provide a path with the directory only or with the logfile.
# /parentdir/logdir
# /parentdir/logdir/logfile.log
#
# It's possible to use this helper several times, each config will be added to the same logrotate config file.
# Unless you use the option --non-append
ynh_use_logrotate () {
	local customtee="tee -a"
	if [ $# -gt 0 ] && [ "$1" == "--non-append" ]; then
		customtee="tee"
		# Destroy this argument for the next command.
		shift
	elif [ $# -gt 1 ] && [ "$2" == "--non-append" ]; then
		customtee="tee"
	fi
	if [ $# -gt 0 ]; then
		if [ "$(echo ${1##*.})" == "log" ]; then	# Keep only the extension to check if it's a logfile
			logfile=$1	# In this case, focus logrotate on the logfile
		else
			logfile=$1/*.log	# Else, uses the directory and all logfile into it.
		fi
	else
		logfile="/var/log/${app}/*.log" # Without argument, use a defaut directory in /var/log
	fi
	cat > ./${app}-logrotate << EOF	# Build a config file for logrotate
$logfile {
		# Rotate if the logfile exceeds 100Mo
	size 100M
		# Keep 12 old log maximum
	rotate 12
		# Compress the logs with gzip
	compress
		# Compress the log at the next cycle. So keep always 2 non compressed logs
	delaycompress
		# Copy and truncate the log to allow to continue write on it. Instead of move the log.
	copytruncate
		# Do not do an error if the log is missing
	missingok
		# Not rotate if the log is empty
	notifempty
		# Keep old logs in the same dir
	noolddir
}
EOF
	sudo mkdir -p $(dirname "$logfile")	# Create the log directory, if not exist
	cat ${app}-logrotate | sudo $customtee /etc/logrotate.d/$app > /dev/null	# Append this config to the existing config file, or replace the whole config file (depending on $customtee)
}


# Get application version from manifest
#
# usage: ynh_app_version
ynh_app_version() {
   manifest_path="../manifest.json"
    if [ ! -e "$manifest_path" ]; then
    	manifest_path="../settings/manifest.json"	# Into the restore script, the manifest is not at the same place
    fi
    echo $(grep '\"version\": ' "$manifest_path" | cut -d '"' -f 4)	# Retrieve the version number in the manifest file.
}