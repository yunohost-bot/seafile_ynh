#=================================================
# SET ALL CONSTANTS
#=================================================

time_zone=$(cat /etc/timezone)

#=================================================
# DEFINE ALL COMMON FONCTIONS
#=================================================

install_dependance() {
    ynh_add_swap --size=2000
    # We need to do that because we can have some issue about the permission access to the pip cache without this
    chown -R $YNH_APP_ID $install_dir
    chmod u+rwX -R $install_dir

    # Note that we install imageio to force the dependance, without this imageio 2.8 is installed and it need python3.5
    sudo -u $YNH_APP_ID pip3 install --user --no-warn-script-location --upgrade future mysqlclient PyMySQL 'Pillow<10.0.0' pylibmc captcha Jinja2 SQLAlchemy psd-tools django-pylibmc django-simple-captcha python3-ldap pycryptodome==3.12.0 cffi==1.14.0 lxml
    ynh_del_swap
}

mv_expect_scripts() {
    expect_scripts_dir=$(mktemp -d)
    cp expect_scripts/* $expect_scripts_dir
    chmod u=rwx,o= -R $expect_scripts_dir
    chown $YNH_APP_ID -R $expect_scripts_dir
}

set_permission() {
    chown -R $YNH_APP_ID:$YNH_APP_ID $install_dir
    chmod -R u+rw,g-wx,o= $install_dir
    setfacl -m user:www-data:rX $install_dir
    setfacl -m user:www-data:rX $install_dir/seafile-server-$seafile_version
    # At install time theses directory are not available
    test -e $install_dir/seafile-server-latest/seahub && setfacl -m user:www-data:rX $install_dir/seafile-server-latest/seahub
    test -e $install_dir/seafile-server-latest/seahub/media && setfacl -R -m user:www-data:rX $install_dir/seafile-server-latest/seahub/media
    test -e $install_dir/seahub-data && setfacl -R -m user:www-data:rX $install_dir/seahub-data

    # check that this directory exist because in some really old install the data could still be in the main seafile directory
    # We also check at the install time when data directory is not already initialised
    if [ -e /home/yunohost.app/seafile-data ]; then
        chown -R $YNH_APP_ID /home/yunohost.app/seafile-data
        chmod -R o= /home/yunohost.app/seafile-data
    fi
}

clean_url_in_db_config() {
    sql_request='DELETE FROM `constance_config` WHERE `constance_key`= "SERVICE_URL"'
    ynh_mysql_execute_as_root --sql "$sql_request" --database seahubdb
    sql_request='DELETE FROM `constance_config` WHERE `constance_key`= "FILE_SERVER_ROOT"'
    ynh_mysql_execute_as_root --sql "$sql_request" --database seahubdb
}
