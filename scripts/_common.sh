#!/bin/bash 

# Retrieve arguments
app=$YNH_APP_INSTANCE_NAME

seafile_version=6.2.2

## Adapt sha256sum while you update app
x86_64sum="4c77721001b1173b11bbc6904dad8d010b7ebe8c0e0d34b5fe60f2158b49c98f"
i386sum="35442c6455da3c76c130dabe12d83f57a50cd080b87f12e4904203dfcffa7900"
armsum="ac153648d6d0e2913c6777604364700cc7ae9d6ebf2bf8de4622c04cfafd0ae6"

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
    if [ "$(lsb_release --codename --short)" == "stretch" ]; then
        ynh_install_app_dependencies python2.7 python-pip python-setuptools python-simplejson python-imaging python-mysqldb python-flup expect python-requests python-dev
    else
        ynh_install_app_dependencies python2.7 python-pip python-setuptools python-simplejson python-pil python-mysqldb python-flup expect python-requests python-dev
    fi
	# Upgrade setuptools for jessie because the new moviepy package is not compatible with setuptools 5.x
	[ "$(lsb_release --codename --short)" = "jessie" ] && pip install --upgrade setuptools
	pip install Pillow 'moviepy<1.0' 'imageio<2.8' certifi idna
}

ynh_clean_setup () {
	pkill -f seafile-controller
	pkill -f seaf-server
	pkill -f ccnet-server
	pkill -f "seahub"
}
