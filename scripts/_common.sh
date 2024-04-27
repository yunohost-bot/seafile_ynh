#=================================================
# SET ALL CONSTANTS
#=================================================

app=$YNH_APP_INSTANCE_NAME

#=================================================
# DEFINE ALL COMMON FONCTIONS
#=================================================

install_source() {
    mkdir "$final_path/seafile-server-$seafile_version"
    if [ $YNH_ARCH == "i386" ] || [ $YNH_ARCH == "armel" ]
    then
        ynh_die --message "Error : this architecture is no longer supported by the upstream. Please create en issue here : https://github.com/YunoHost-Apps/seafile_ynh/issues to ask to discuss about a support of this architecture"
    fi
    ynh_setup_source "$final_path/seafile-server-$seafile_version" "$YNH_ARCH"

    # Drop some conflicting package cf: https://forum.seafile.com/t/seahub-fails-to-start-nameerror-name-mysql-is-not-defined/14566/3
    ynh_secure_remove --file=$final_path/seafile-server-$seafile_version/seahub/thirdpart/MySQLdb
    ynh_secure_remove --file=$final_path/seafile-server-$seafile_version/seahub/thirdpart/cffi
    ynh_secure_remove --file=$final_path/seafile-server-$seafile_version/seahub/thirdpart/PIL
}

install_source_7_0() {
    if ! [ -e $final_path/seafile-server-7.0.5 ]; then
        mkdir "$final_path/seafile-server-7.0.5"
        if [ $YNH_ARCH == "i386" ] || [ $YNH_ARCH == "armel" ]
        then
            ynh_die --message "Error : this architecture is no longer supported by the upstream. Please create en issue here : https://github.com/YunoHost-Apps/seafile_ynh/issues to ask to discuss about a support of this architecture"
        fi
        ynh_setup_source "$final_path/seafile-server-7.0.5" "$YNH_ARCH"_7_0
    fi
}

install_dependance() {
    ynh_install_app_dependencies python3 python3-setuptools python3-pip python3-requests python3-dev libmariadb-dev-compat libmariadb-dev \
        expect ffmpeg \
        memcached libmemcached-dev \
        python3-scipy python3-matplotlib \
        libjpeg62-turbo-dev zlib1g-dev libffi-dev  # For building pillow
    ynh_add_swap --size=2000
    # We need to do that because we can have some issue about the permission access to the pip cache without this
    chown -R $seafile_user:$seafile_user $final_path

    # Note that we install imageio to force the dependance, without this imageio 2.8 is installed and it need python3.5
    if [ $(lsb_release --codename --short) == bullseye ]; then
        sudo -u $seafile_user pip3 install --no-warn-script-location --user --upgrade future mysqlclient PyMySQL 'Pillow<10.0.0' pylibmc captcha Jinja2 SQLAlchemy psd-tools django-pylibmc django-simple-captcha python3-ldap pycryptodome==3.12.0 cffi==1.14.1
    else
        sudo -u $seafile_user pip3 install --break-system-packages --user --no-warn-script-location --upgrade future mysqlclient PyMySQL 'Pillow<10.0.0' pylibmc captcha Jinja2 SQLAlchemy psd-tools django-pylibmc django-simple-captcha python3-ldap pycryptodome==3.12.0 cffi==1.14.1
    fi
    # TODO add dependance when upgrade to seafile 8: django==2.2.*
    ynh_del_swap
}

mv_expect_scripts() {
    expect_scripts_dir=$(mktemp -d)
    cp expect_scripts/* $expect_scripts_dir
    chmod u=rwx,o= -R $expect_scripts_dir
    chown $seafile_user -R $expect_scripts_dir
}

set_permission() {
    chown -R $seafile_user:$seafile_user $final_path
    chmod -R g-wx,o= $final_path
    setfacl -m user:www-data:rX $final_path
    setfacl -m user:www-data:rX $final_path/seafile-server-$seafile_version
    # At install time theses directory are not available
    test -e $final_path/seafile-server-latest/seahub && setfacl -m user:www-data:rX $final_path/seafile-server-latest/seahub
    test -e $final_path/seafile-server-latest/seahub/media && setfacl -R -m user:www-data:rX $final_path/seafile-server-latest/seahub/media
    test -e $final_path/seahub-data && setfacl -R -m user:www-data:rX $final_path/seahub-data

    # check that this directory exist because in some really old install the data could still be in the main seafile directory
    # We also check at the install time when data directory is not already initialised
    if [ -e /home/yunohost.app/seafile-data ]; then
        chown -R $seafile_user:$seafile_user /home/yunohost.app/seafile-data
        chmod -R o= /home/yunohost.app/seafile-data
    fi
}

ynh_clean_setup () {
	pkill -f seafile-controller
	pkill -f seaf-server
	pkill -f ccnet-server
	pkill -f seahub
}
