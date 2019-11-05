#!/usr/bin/env python

import sys
import os
from seaserv import seafile_api, ccnet_api

seafile_local_emails = map(lambda user: user.email, ccnet_api.get_emailusers('DB', start=-1, limit=-1, is_active=None))
active_user_emails = map(lambda user: user.email, ccnet_api.get_emailusers(source='LDAPImport', start=-1, limit=-1, is_active=True))
ldap_user_emails = map(lambda user: user.email, ccnet_api.get_emailusers(source='LDAP', start=-1, limit=-1, is_active=None))
non_active_user_emails = list(set(ldap_user_emails) - set(active_user_emails))

seafile_domain = os.environ['SEAFILE_CURRENT_DOMAIN']
source_user = sys.argv[1]
source_user_email = source_user + '@' + seafile_domain
assert (source_user_email in seafile_local_emails), 'The user must be in local seafile users list'

# TODO we might want to use non_active_user_emails in place of ldap_user_emails here
filtered_potencial_target_users = list(filter(lambda email: email.startswith(source_user + '@'), ldap_user_emails))
assert (not len(filtered_potencial_target_users) > 1), 'This user have multiple target possible can\'t continue'
assert (len(filtered_potencial_target_users) == 1), 'This user doesn\'t have any possible match in Yunohost LDAP'

target_user_email = filtered_potencial_target_users[0]

ccnet_api.get_emailuser_with_import(target_user_email)

source_repositories = seafile_api.get_owned_repo_list(source_user_email);

for repo in source_repositories:
    seafile_api.set_repo_owner(repo.id, target_user_email)
