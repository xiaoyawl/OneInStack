#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Project home page:
#       http://oneinstack.com
#       https://github.com/lj2007331/oneinstack

DEMO()
{
cd $oneinstack_dir/src

[ "$IPADDR_STATE"x == "CN"x ] && /bin/cp ../config/index_cn.html $wwwroot_dir/default/index.html || /bin/cp ../config/index.html $wwwroot_dir/default

if [ -e "$php_install_dir/bin/php" ];then
    if [ "$IPADDR_STATE"x == "CN"x ];then
        src_url=http://mirrors.linuxeye.com/oneinstack/src/tz.zip && Download_src
        unzip -q tz.zip -d $wwwroot_dir/default
    else
        src_url=http://mirrors.linuxeye.com/oneinstack/src/tz_e.zip && Download_src
        unzip -q tz_e.zip -d $wwwroot_dir/default;/bin/mv $wwwroot_dir/default/{tz_e.php,proberv.php}
        sed -i 's@https://ajax.googleapis.com/ajax/libs/jquery/1.7.0/jquery.min.js@http://lib.sinaapp.com/js/jquery/1.7/jquery.min.js@' $wwwroot_dir/default/proberv.php
    fi

    echo '<?php phpinfo() ?>' > $wwwroot_dir/default/phpinfo.php
    src_url=http://mirrors.linuxeye.com/oneinstack/src/ocp.php && Download_src
    [ "$PHP_cache" == '1' ] && /bin/cp ocp.php $wwwroot_dir/default && sed -i 's@<a href="/xcache" target="_blank" class="links">xcache</a>@<a href="/ocp.php" target="_blank" class="links">Opcache</a>@' $wwwroot_dir/default/index.html
    [ "$PHP_cache" == '3' ] && sed -i 's@<a href="/xcache" target="_blank" class="links">xcache</a>@<a href="/apc.php" target="_blank" class="links">APC</a>@' $wwwroot_dir/default/index.html
    [ "$PHP_cache" == '4' ] && /bin/cp eaccelerator-*/control.php $wwwroot_dir/default && sed -i 's@<a href="/xcache" target="_blank" class="links">xcache</a>@<a href="/control.php" target="_blank" class="links">eAccelerator</a>@' $wwwroot_dir/default/index.html
fi
chown -R ${run_user}.$run_user $wwwroot_dir/default
cd ..
}
