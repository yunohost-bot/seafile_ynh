<!--
N.B.: This README was automatically generated by https://github.com/YunoHost/apps/tree/master/tools/README-generator
It shall NOT be edited by hand.
-->

# Seafile for YunoHost

[![Integration level](https://dash.yunohost.org/integration/seafile.svg)](https://dash.yunohost.org/appci/app/seafile) ![Working status](https://ci-apps.yunohost.org/ci/badges/seafile.status.svg) ![Maintenance status](https://ci-apps.yunohost.org/ci/badges/seafile.maintain.svg)

[![Install Seafile with YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=seafile)

*[Lire ce readme en français.](./README_fr.md)*

> *This package allows you to install Seafile quickly and simply on a YunoHost server.
If you don't have YunoHost, please consult [the guide](https://yunohost.org/#/install) to learn how to install it.*

## Overview

Seafile is an open Source Cloud Storage application.

It's a Enterprise file sync and share platform with high reliability and performance. It's a file hosting platform with high reliability and performance. Put files on your own server. Sync and share files across different devices, or access all the files as a virtual disk.


**Shipped version:** 9.0.9~ynh1

**Demo:** https://demo.seafile.com

## Screenshots

![Screenshot of Seafile](./doc/screenshots/mobile-ios-client.jpg)
![Screenshot of Seafile](./doc/screenshots/drive-client.png)
![Screenshot of Seafile](./doc/screenshots/file-locking.jpg)
![Screenshot of Seafile](./doc/screenshots/access-logs.jpg)
![Screenshot of Seafile](./doc/screenshots/file-history.png)
![Screenshot of Seafile](./doc/screenshots/wiki_en.png)
![Screenshot of Seafile](./doc/screenshots/sharing-dialog.png)
![Screenshot of Seafile](./doc/screenshots/sync-client.jpg)

## Documentation and resources

* Official app website: <https://www.seafile.com>
* Official admin documentation: <https://manual.seafile.com>
* Upstream app code repository: <https://github.com/haiwen/seafile-server>
* Report a bug: <https://github.com/YunoHost-Apps/seafile_ynh/issues>

## Developer info

Please send your pull request to the [testing branch](https://github.com/YunoHost-Apps/seafile_ynh/tree/testing).

To try the testing branch, please proceed like that.

``` bash
sudo yunohost app install https://github.com/YunoHost-Apps/seafile_ynh/tree/testing --debug
or
sudo yunohost app upgrade seafile -u https://github.com/YunoHost-Apps/seafile_ynh/tree/testing --debug
```

**More info regarding app packaging:** <https://yunohost.org/packaging_apps>
