#!/bin/bash

# Source YunoHost helpers
source /usr/share/yunohost/helpers

# Stop script if errors
#ynh_abort_if_errors

# Import common cmd
#source ./experimental_helper.sh
#source ./_common.sh

final_path=$(ynh_app_setting_get --app $YNH_APP_INSTANCE_NAME --key final_path)

export SEAFILE_CURRENT_DOMAIN=$(ynh_app_setting_get --app $YNH_APP_INSTANCE_NAME --key domain)
export CCNET_CONF_DIR=$final_path/ccnet
export SEAFILE_CONF_DIR=$final_path/conf
export SEAFILE_CENTRAL_CONF_DIR=$final_path/conf

export PYTHONPATH=$final_path/seafile-server-latest/seafile/lib/python2.7/site-packages:$final_path/seafile-server-latest/seafile/lib64/python2.7/site-packages:$PYTHONPATH

python $*
