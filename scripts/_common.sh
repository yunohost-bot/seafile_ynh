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
	final_path=$(ynh_app_setting_get --app $app --key final_path)
	seafile_user=$(ynh_app_setting_get --app $app --key seafile_user)
	
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
			ynh_die --message "Error : can't find seafile path"
		fi
		ynh_app_setting_set --app $app --key final_path --value $final_path
		ynh_app_setting_set --app $app --key seafile_user --value $seafile_user
    fi
}

install_source() {
    mkdir "$final_path/seafile-server-$seafile_version"
    if [[ $architecture == "i386" ]]
    then
        ynh_die --message "Error : this architecture is no longer supported by the upstream. Please create en issue here : https://github.com/YunoHost-Apps/seafile_ynh/issues to ask to discuss about a support of this architecture"
    fi
    ynh_setup_source "$final_path/seafile-server-$seafile_version" "$architecture"
}

install_dependance() {
	ynh_install_app_dependencies python2.7 python-pip libpython2.7 python-setuptools python-ldap python-urllib3 python-simplejson python-imaging python-mysqldb python-flup expect python-requests python-dev ffmpeg python-memcache \
        libjpeg62-turbo-dev zlib1g-dev # For building pillow
    if [[ "$seafile_user" == seafile ]] && [[ "$final_path" == "/opt/yunohost/$app" ]] ; then
		sudo -u $seafile_user pip install --user --upgrade Pillow 'moviepy<1.0'
	else
		pip install --upgrade Pillow 'moviepy<1.0'
	fi
}

set_permission() {
    chown -R $seafile_user:$seafile_user $final_path
}

ynh_clean_setup () {
	pkill -f seafile-controller
	pkill -f seaf-server
	pkill -f ccnet-server
	pkill -f seahub
}
