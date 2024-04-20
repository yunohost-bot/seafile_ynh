#=================================================
# SET ALL CONSTANTS
#=================================================

time_zone=$(cat /etc/timezone)
python_version="$(python3 -V | cut -d' ' -f2 | cut -d. -f1-2)"

# Create special path with / at the end
if [[ $path == '/' ]]
then
    path2="$path"
else
    path2="$path/"
fi

#=================================================
# DEFINE ALL COMMON FONCTIONS
#=================================================

install_pkg_conf() {
    # Install manually pkgconf
    # WARNING don't move this to dependencies
    # We install this manually because we have an issue between pkgconf and pkg-config.
    # If pkg-config is already installed on the system we can't declare pkgconf as dependency as pkg-config need to be removed to install pkgconf (note that pkgconf replace pkg-config and both can't be installed)
    ynh_apt install pkgconf
}

install_dependance() {
    ynh_add_swap --size=2000

    # Clean venv is it was on python3 with old version in case major upgrade of debian
    if [ ! -e $install_dir/venv/bin/python3 ] || [ ! -e $install_dir/venv/lib/python$python_version ]; then
        ynh_secure_remove --file=$install_dir/venv/bin
        ynh_secure_remove --file=$install_dir/venv/lib
        ynh_secure_remove --file=$install_dir/venv/lib64
        ynh_secure_remove --file=$install_dir/venv/include
        ynh_secure_remove --file=$install_dir/venv/share
        ynh_secure_remove --file=$install_dir/venv/pyvenv.cfg
    fi

    # Create venv if it don't exist
    test -e $install_dir/venv/bin/python3 || python3 -m venv $install_dir/venv

    u_arg='u'
    set +$u_arg;
    source $install_dir/venv/bin/activate
    set -$u_arg;

    # Note that we install imageio to force the dependance, without this imageio 2.8 is installed and it need python3.5
    if [ $(lsb_release --codename --short) == "bookworm" ]; then
        # Fix cffi installtion issue cf: https://github.com/haiwen/seahub/issues/5166
        pip3 install --upgrade 'cffi==1.15.1'
        sed -e "s|1.14.0|1.15.1|" -i $install_dir/seafile-server-$seafile_version/seahub/thirdpart/cffi/__init__.py
    else
        pip3 install --upgrade cffi==1.14.0
    fi
    if [ -n "$(uname -m | grep x86_64)" ]; then
        py_dependancy="django==3.2.* Pillow<10.0.0 pylibmc captcha jinja2 SQLAlchemy<2 django-pylibmc django-simple-captcha python3-ldap mysqlclient pycryptodome==3.12.0 lxml python3-ldap"
    else
        py_dependancy="lxml python3-ldap"
    fi
    pip3 install --upgrade --timeout=3600 $py_dependancy

    set +$u_arg;
    deactivate
    set -$u_arg;
    ynh_del_swap

    # Create symbolic link to venv package on seahub
    ls $install_dir/venv/lib/python$python_version/site-packages | while read f; do
        if [ ! -e "$install_dir/seafile-server-$seafile_version/seahub/thirdpart/$f" ]; then
            ln -s ../../../venv/lib/python$python_version/site-packages/$f $install_dir/seafile-server-$seafile_version/seahub/thirdpart/$f
        fi
    done
}

set_permission() {
    chown -R $app:$app $install_dir
    chmod -R u+rwX,g-wx,o= $install_dir
    setfacl -m user:www-data:rX $install_dir
    setfacl -m user:www-data:rX $install_dir/seafile-server-$seafile_version
    # At install time theses directory are not available
    test -e $install_dir/seafile-server-$seafile_version/seahub && setfacl -m user:www-data:rX $install_dir/seafile-server-$seafile_version/seahub
    test -e $install_dir/seafile-server-$seafile_version/seahub/media && setfacl -R -m user:www-data:rX $install_dir/seafile-server-$seafile_version/seahub/media
    test -e $install_dir/seahub-data && setfacl -R -m user:www-data:rX $install_dir/seahub-data

    find $data_dir \(   \! -perm -o= \
                     -o \! -user $app \
                     -o \! -group $app \) \
                   -exec chown $app:$app {} \; \
                   -exec chmod o= {} \;
}

clean_url_in_db_config() {
    sql_request='DELETE FROM `constance_config` WHERE `constance_key`= "SERVICE_URL"'
    ynh_mysql_execute_as_root --sql "$sql_request" --database seahubdb
    sql_request='DELETE FROM `constance_config` WHERE `constance_key`= "FILE_SERVER_ROOT"'
    ynh_mysql_execute_as_root --sql "$sql_request" --database seahubdb
}
