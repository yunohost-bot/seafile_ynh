#=================================================
# SET ALL CONSTANTS
#=================================================

app=$YNH_APP_INSTANCE_NAME
[[ -e "../settings/manifest.json" ]] || [[ -e "../manifest.json" ]] && \
    seafile_version=$(ynh_app_upstream_version)

#=================================================
# DEFINE ALL COMMON FONCTIONS
#=================================================

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

	# In the 3.x seafile version package the seahub_port and fileserver_port wasn't saved in the settings. If the settings is empty we try to get it and save in the settings

	if [[ -z $seahub_port ]] || [[ -z $fileserver_port ]]
	then
		seahub_port=$(head -n 20 /etc/nginx/conf.d/$domain.d/seafile.conf | grep -E "fastcgi_pass.*127.0.0.1:" | cut -d':' -f2 | cut -d';' -f1)
		fileserver_port=$(head -n 50 /etc/nginx/conf.d/$domain.d/seafile.conf | grep -E "proxy_pass.*127.0.0.1:" | cut -d':' -f3 | cut -d';' -f1 | cut -d'/' -f1)

		ynh_app_setting_set $app seahub_port $seahub_port
		ynh_app_setting_set $app fileserver_port $fileserver_port
	fi

    ynh_add_nginx_config 'seahub_port fileserver_port webdav_port'
}

install_source() {
    mkdir "$final_path/seafile-server-$seafile_version"
    ynh_setup_source "$final_path/seafile-server-$seafile_version" "$architecture"
}

install_dependance() {
	ynh_install_app_dependencies python2.7 python-pip python-setuptools python-simplejson python-imaging python-mysqldb python-flup expect python-requests python-dev \
        libjpeg62-turbo-dev zlib1g-dev # For building pillow
	# Upgrade setuptools for jessie because the new moviepy package is not compatible with setuptools 5.x
	[ "$(lsb_release --codename --short)" = "jessie" ] && pip install --upgrade setuptools
	pip install --upgrade pillow moviepy
}

ynh_clean_setup () {
	pkill -f seafile-controller
	pkill -f seaf-server
	pkill -f ccnet-server
	pkill -f "seahub"
}
