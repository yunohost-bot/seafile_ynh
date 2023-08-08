#=================================================
# SET ALL CONSTANTS
#=================================================

db_user=seafile
time_zone=$(cat /etc/timezone)

#=================================================
# DEFINE ALL COMMON FONCTIONS
#=================================================

install_dependance() {
    ynh_add_swap --size=2000
    # We need to do that because we can have some issue about the permission access to the pip cache without this
    chown -R $seafile_user:$seafile_user $install_dir

    # Note that we install imageio to force the dependance, without this imageio 2.8 is installed and it need python3.5
    sudo -u $seafile_user pip3 install --user --no-warn-script-location --upgrade future mysqlclient PyMySQL Pillow pylibmc captcha Jinja2 SQLAlchemy psd-tools django-pylibmc django-simple-captcha python3-ldap pycryptodome==3.12.0 cffi==1.14.0
    ynh_del_swap
}

mv_expect_scripts() {
    expect_scripts_dir=$(mktemp -d)
    cp expect_scripts/* $expect_scripts_dir
    chmod u=rwx,o= -R $expect_scripts_dir
    chown $seafile_user -R $expect_scripts_dir
}

set_permission() {
    chown -R $seafile_user:$seafile_user $install_dir
    chmod -R g-wx,o= $install_dir
    setfacl -m user:www-data:rX $install_dir
    setfacl -m user:www-data:rX $install_dir/seafile-server-$seafile_version
    # At install time theses directory are not available
#REMOVEME?     test -e $install_dir/seafile-server-latest/seahub && setfacl -m user:www-data:rX $install_dir/seafile-server-latest/seahub
#REMOVEME?     test -e $install_dir/seafile-server-latest/seahub/media && setfacl -R -m user:www-data:rX $install_dir/seafile-server-latest/seahub/media
#REMOVEME?     test -e $install_dir/seahub-data && setfacl -R -m user:www-data:rX $install_dir/seahub-data

    # check that this directory exist because in some really old install the data could still be in the main seafile directory
    # We also check at the install time when data directory is not already initialised
    if [ -e /home/yunohost.app/seafile-data ]; then
        chown -R $seafile_user:$seafile_user /home/yunohost.app/seafile-data
        chmod -R o= /home/yunohost.app/seafile-data
    fi
}
