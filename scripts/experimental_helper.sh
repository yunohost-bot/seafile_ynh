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

# Read the value of a key in a ynh manifest file
#
# usage: ynh_read_manifest manifest key
# | arg: manifest - Path of the manifest to read
# | arg: key - Name of the key to find
ynh_read_manifest () {
	manifest="$1"
	key="$2"
	python3 -c "import sys, json;print(json.load(open('$manifest', encoding='utf-8'))['$key'])"
}

# Read the upstream version from the manifest 
# The version number in the manifest is defined by <upstreamversion>~ynh<packageversion>
# For example : 4.3-2~ynh3
# This include the number before ~ynh
# In the last example it return 4.3-2
#
# usage: ynh_app_upstream_version
ynh_app_upstream_version () {
    manifest_path="../manifest.json"
    if [ ! -e "$manifest_path" ]; then
        manifest_path="../settings/manifest.json"	# Into the restore script, the manifest is not at the same place
    fi
    version_key=$(ynh_read_manifest "$manifest_path" "version")
    echo "${version_key/~ynh*/}"
}

# Read package version from the manifest
# The version number in the manifest is defined by <upstreamversion>~ynh<packageversion>
# For example : 4.3-2~ynh3
# This include the number after ~ynh
# In the last example it return 3
#
# usage: ynh_app_package_version
ynh_app_package_version () {
    manifest_path="../manifest.json"
    if [ ! -e "$manifest_path" ]; then
        manifest_path="../settings/manifest.json"	# Into the restore script, the manifest is not at the same place
    fi
    version_key=$(ynh_read_manifest "$manifest_path" "version")
    echo "${version_key/*~ynh/}"
} 


# Create a dedicated nginx config
#
# usage: ynh_add_nginx_config "list of others variables to replace"
#
# | arg: list of others variables to replace separeted by a space
# |      for example : 'path_2 port_2 ...'
#
# This will use a template in ../conf/nginx.conf
#   __PATH__      by  $path_url
#   __DOMAIN__    by  $domain
#   __PORT__      by  $port
#   __NAME__      by  $app
#   __FINALPATH__ by  $final_path
#
#  And dynamic variables (from the last example) :
#   __PATH_2__    by $path_2
#   __PORT_2__    by $port_2
#
ynh_add_nginx_config () {
	local finalnginxconf="/etc/nginx/conf.d/$domain.d/$app.conf"
	local others_var=${1:-}
	ynh_backup_if_checksum_is_different "$finalnginxconf"
	sudo cp ../conf/nginx.conf "$finalnginxconf"

	# To avoid a break by set -u, use a void substitution ${var:-}. If the variable is not set, it's simply set with an empty variable.
	# Substitute in a nginx config file only if the variable is not empty
	if test -n "${path_url:-}"; then
		# path_url_slash_less is path_url, or a blank value if path_url is only '/'
		local path_url_slash_less=${path_url%/}
		ynh_replace_string "__PATH__/" "$path_url_slash_less/" "$finalnginxconf"
		ynh_replace_string "__PATH__" "$path_url" "$finalnginxconf"
	fi
	if test -n "${domain:-}"; then
		ynh_replace_string "__DOMAIN__" "$domain" "$finalnginxconf"
	fi
	if test -n "${port:-}"; then
		ynh_replace_string "__PORT__" "$port" "$finalnginxconf"
	fi
	if test -n "${app:-}"; then
		ynh_replace_string "__NAME__" "$app" "$finalnginxconf"
	fi
	if test -n "${final_path:-}"; then
		ynh_replace_string "__FINALPATH__" "$final_path" "$finalnginxconf"
	fi
	
	# Replace all other variable given as arguments
	for v in $others_var
	do
        ynh_replace_string "__${v^^}__" "${!v}" "$finalnginxconf"
	done
	
    if [ "${path_url:-}" != "/" ]
    then
        ynh_replace_string "^#sub_path_only" "" "$finalnginxconf"
    fi

	ynh_store_file_checksum "$finalnginxconf"

	sudo systemctl reload nginx
}

# Delete a file checksum from the app settings
#
# $app should be defined when calling this helper
#
# usage: ynh_remove_file_checksum file
# | arg: file - The file for which the checksum will be deleted
ynh_delete_file_checksum () {
	local checksum_setting_name=checksum_${1//[\/ ]/_}	# Replace all '/' and ' ' by '_'
	ynh_app_setting_delete $app $checksum_setting_name
}

# Reload (or other actions) a service and print a log in case of failure.
#
# usage: ynh_system_reload service_name [action]
# | arg: service_name - Name of the service to reload
# | arg: action - Action to perform with systemctl. Default: reload
ynh_system_reload () {
        local service_name=$1
        local action=${2:-reload}

        # Reload, restart or start and print the log if the service fail to start or reload
        systemctl $action $service_name || ( journalctl --lines=20 -u $service_name >&2 && false)
}
