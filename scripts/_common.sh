#=================================================
# SET ALL CONSTANTS
#=================================================

readonly time_zone="$(cat /etc/timezone)"
readonly python_version="$(python3 -V | cut -d' ' -f2 | cut -d. -f1-2)"
systemd_seafile_bind_mount="$data_dir/seafile-data:/opt/seafile/seafile-data "
systemd_seafile_bind_mount+="$data_dir/seahub-data:/opt/seafile/seahub-data "
systemd_seafile_bind_mount+="/var/log/$app:/opt/seafile/logs "
systemd_seafile_bind_mount+="$install_dir/conf:/opt/seafile/conf "
systemd_seafile_bind_mount+="$install_dir/ccnet:/opt/seafile/ccnet "
systemd_seafile_bind_mount+="/proc "
systemd_seafile_bind_mount+="/dev"

# Create special path with / at the end
if [[ "$path" == '/' ]]
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

run_seafile_cmd() {
    ynh_exec_warn_less systemd-run --wait --uid="$app" --gid="$app" \
        --property=RootDirectory="$install_dir"/seafile_image \
        --property="BindPaths=$systemd_seafile_bind_mount" \
        $@
}

install_source() {
    ynh_setup_source_custom --dest_dir="$install_dir"/seafile_image --full_replace
    mkdir -p "$install_dir"/seafile_image/opt/seafile/{seafile-data,seahub-data,conf,ccnet,logs}
    grep "^$app:x"  /etc/passwd | sed "s|$install_dir|/opt/seafile|" >> "$install_dir"/seafile_image/etc/passwd
    grep "^$app:x"  /etc/group >> "$install_dir"/seafile_image/etc/group
    grep "^$app:x"  /etc/group- >> "$install_dir"/seafile_image/etc/group-
    grep "^$app:"  /etc/shadow >> "$install_dir"/seafile_image/etc/shadow
}

set_permission() {
    chown -R "$app:$app" "$install_dir"/{conf,ccnet}
    chmod -R u+rwX,g-w,o= "$install_dir"/{conf,ccnet}
    chown -R "$app:$app" "$install_dir"/seafile_image/opt/seafile
    chmod -R u+rwX,g-w,o= "$install_dir"/seafile_image/opt/seafile

    # Allow to www-data to each dir between /opt/yunohost/seafile and /opt/yunohost/seafile/seafile_image/opt/seafile/seahub/media
    local dir_path=''
    while read -r -d/ dir_name; do
        dir_path+="$dir_name/"
        if [[ "$dir_path" == "$install_dir"* ]] && [ -e "$dir_path" ]; then
            setfacl -m user:www-data:rX "$dir_path"
        fi
    done <<< "$seafile_code/seahub/media"
    test -e "$install_dir/seafile_image/opt/seafile/seahub-data" && setfacl -m user:www-data:rX "$install_dir/seafile_image/opt/seafile/seahub-data"
    test -e "$seafile_code/seahub/media" && setfacl -R -m user:www-data:rX "$seafile_code/seahub/media"

    # At install time theses directory are not available
    test -e "$install_dir"/seahub-data && setfacl -m user:www-data:rX "$data_dir"
    test -e "$install_dir"/seahub-data && setfacl -R -m user:www-data:rX "$data_dir"/seahub-data

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
