#=================================================
# SET ALL CONSTANTS
#=================================================

readonly time_zone="$(cat /etc/timezone)"
readonly python_version="$(python3 -V | cut -d' ' -f2 | cut -d. -f1-2)"

# Create special path with / at the end
if [[ $path == '/' ]]
then
    readonly path2="$path"
else
    readonly path2="$path/"
fi

if [ "${LANG:0:2}" == C. ]; then
    readonly language=en
else
    readonly language="${LANG:0:2}"
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

    py_dependancy="django==4.2.* future==0.18.* mysqlclient==2.1.* pymysql pillow==10.2.* pylibmc captcha==0.5.* markupsafe==2.0.1 jinja2 sqlalchemy==2.0.18 psd-tools django-pylibmc django_simple_captcha==0.6.* djangosaml2==1.5.* pysaml2==7.2.* pycryptodome==3.16.* cffi==1.15.1 lxml python-ldap==3.4.3"
    $install_dir/venv/bin/pip3 install --upgrade --timeout=3600 $py_dependancy

    # Create symbolic link to venv package on seahub
    ls "$install_dir/venv/lib/python$python_version/site-packages" | while read -r f; do
        if [ ! -e "$install_dir/seafile-server-$seafile_version/seahub/thirdpart/$f" ]; then
            ln -s "../../../venv/lib/python$python_version/site-packages/$f" "$install_dir/seafile-server-$seafile_version/seahub/thirdpart/$f"
        fi
    done
}

install_source() {
    ynh_setup_source --dest_dir="$install_dir"/docker_image --full_replace
    ynh_secure_remove --file="$install_dir/seafile-server-$seafile_version"
    mv "$install_dir/docker_image/opt/seafile/seafile-server-$seafile_version" "$install_dir/seafile-server-$seafile_version"
    ynh_secure_remove --file="$install_dir"/docker_image
}

set_permission() {
    chown -R "$app:$app" "$install_dir"
    chmod -R u+rwX,g-wx,o= "$install_dir"
    setfacl -m user:www-data:rX "$install_dir"
    setfacl -m user:www-data:rX "$install_dir/seafile-server-$seafile_version"
    # At install time theses directory are not available
    test -e $install_dir/seafile-server-$seafile_version/seahub && setfacl -m user:www-data:rX $install_dir/seafile-server-$seafile_version/seahub
    test -e $install_dir/seafile-server-$seafile_version/seahub/media && setfacl -R -m user:www-data:rX $install_dir/seafile-server-$seafile_version/seahub/media
    test -e $install_dir/seahub-data && setfacl -m user:www-data:rX $data_dir
    test -e $install_dir/seahub-data && setfacl -R -m user:www-data:rX $data_dir/seahub-data

    find "$data_dir" \(   \! -perm -o= \
                     -o \! -user "$app" \
                     -o \! -group "$app" \) \
                   -exec chown "$app:$app" {} \; \
                   -exec chmod o= {} \;
}

clean_url_in_db_config() {
    sql_request='DELETE FROM `constance_config` WHERE `constance_key`= "SERVICE_URL"'
    ynh_mysql_execute_as_root --sql="$sql_request" --database=seahubdb
    sql_request='DELETE FROM `constance_config` WHERE `constance_key`= "FILE_SERVER_ROOT"'
    ynh_mysql_execute_as_root --sql="$sql_request" --database=seahubdb
}

ensure_vars_set() {
    if [ -z "${jwt_private_key_notification_server:-}" ]; then
        jwt_private_key_notification_server=$(ynh_string_random -l 32)
        ynh_app_setting_set --app="$app" --key=jwt_private_key_notification_server --value="$jwt_private_key_notification_server"
    fi
}
