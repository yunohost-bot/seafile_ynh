#!/bin/bash 

# Retrieve arguments
app=$YNH_APP_INSTANCE_NAME

seafile_version=6.1.1

## Adapt md5sum while you update app
x86_64sum="3f887d018bd7eaa8b4e1e7830f365802311686636227f1c08a8c48e89aefc35c"
i386sum="6d236c93f5a5f674c52b943428995cfe046965f17f2df9f644e17a704072603b"
armsum="e40a8f3a91a4629428288aaabe4a2d6906dd00afc08faf08916f30b8c5a312e4"

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

config_nginx() {
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
	ynh_install_app_dependencies python2.7 python-setuptools python-simplejson python-imaging python-mysqldb python-flup expect ffmpeg python-requests python-dev
	pip install pillow moviepy
}

ynh_clean_setup () {
	pkill -f seafile-controller
	pkill -f seaf-server
	pkill -f ccnet-server
	pkill -f "seahub"
}
