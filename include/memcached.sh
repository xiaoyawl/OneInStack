#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Project home page:
#       http://oneinstack.com
#       https://github.com/lj2007331/oneinstack

Install_memcached() {
cd $oneinstack_dir/src
src_url=http://www.memcached.org/files/memcached-$memcached_version.tar.gz && Download_src

# memcached server
id -u memcached >/dev/null 2>&1
[ $? -ne 0 ] && useradd -M -s /sbin/nologin memcached

tar xzf memcached-$memcached_version.tar.gz
cd memcached-$memcached_version
[ ! -d "$memcached_install_dir" ] && mkdir -p $memcached_install_dir
./configure --prefix=$memcached_install_dir
make && make install
if [ -d "$memcached_install_dir/include/memcached" ];then
    echo "${CSUCCESS}memcached install successfully! ${CEND}"
    cd ..
    rm -rf memcached-$memcached_version
    ln -s $memcached_install_dir/bin/memcached /usr/bin/memcached
    OS_CentOS='/bin/cp ../init.d/Memcached-init-CentOS /etc/init.d/memcached \n
chkconfig --add memcached \n
chkconfig memcached on'
    OS_Debian_Ubuntu='/bin/cp ../init.d/Memcached-init-Ubuntu /etc/init.d/memcached \n
update-rc.d memcached defaults'
    OS_command
    sed -i "s@/usr/local/memcached@$memcached_install_dir@g" /etc/init.d/memcached
    [ -n "`grep 'CACHESIZE=' /etc/init.d/memcached`" ] && sed -i "s@^CACHESIZE=.*@CACHESIZE=`expr $Mem / 8`@" /etc/init.d/memcached 
    [ -n "`grep 'start_instance default 256;' /etc/init.d/memcached`" ] && sed -i "s@start_instance default 256;@start_instance default `expr $Mem / 8`;@" /etc/init.d/memcached
    service memcached start
else
    rm -rf $memcached_install_dir
    echo "${CFAILURE}memcached install failed, Please contact the author! ${CEND}"
    kill -9 $$
fi
cd ..
}

Install_php-memcache() {
cd $oneinstack_dir/src
if [ -e "$php_install_dir/bin/phpize" ];then
    src_url=http://pecl.php.net/get/memcache-$memcache_pecl_version.tgz && Download_src
    # php memcache extension
    tar xzf memcache-$memcache_pecl_version.tgz 
    cd memcache-$memcache_pecl_version 
    make clean
    $php_install_dir/bin/phpize
    ./configure --with-php-config=$php_install_dir/bin/php-config
    make && make install
    if [ -f "`$php_install_dir/bin/php-config --extension-dir`/memcache.so" ];then
        [ -z "`grep '^extension_dir' $php_install_dir/etc/php.ini`" ] && sed -i "s@extension_dir = \"ext\"@extension_dir = \"ext\"\nextension_dir = \"`$php_install_dir/bin/php-config --extension-dir`\"@" $php_install_dir/etc/php.ini
        [ -z "`grep 'memcache.so' $php_install_dir/etc/php.ini`" ] && sed -i 's@^extension_dir\(.*\)@extension_dir\1\nextension = "memcache.so"@' $php_install_dir/etc/php.ini
        [ "$Apache_version" != '1' -a "$Apache_version" != '2' ] && service php-fpm restart || service httpd restart
        echo "${CSUCCESS}PHP memcache module install successfully! ${CEND}"
        cd ..
        rm -rf memcache-$memcache_pecl_version
    else
        echo "${CFAILURE}PHP memcache module install failed, Please contact the author! ${CEND}" 
    fi
fi
cd ..
}

Install_php-memcached() {
cd $oneinstack_dir/src
if [ -e "$php_install_dir/bin/phpize" ];then
    src_url=https://launchpad.net/libmemcached/1.0/$libmemcached_version/+download/libmemcached-$libmemcached_version.tar.gz && Download_src
    src_url=http://pecl.php.net/get/memcached-$memcached_pecl_version.tgz && Download_src
    # php memcached extension
    tar xzf libmemcached-$libmemcached_version.tar.gz
    cd libmemcached-$libmemcached_version
    OS_CentOS='yum -y install cyrus-sasl-devel'
    OS_Debian_Ubuntu='sed -i "s@lthread -pthread -pthreads@lthread -lpthread -pthreads@" ./configure'
    OS_command
    ./configure --with-memcached=$memcached_install_dir
    make && make install
    cd ..
    rm -rf libmemcached-$libmemcached_version

    tar xzf memcached-$memcached_pecl_version.tgz
    cd memcached-$memcached_pecl_version
    make clean
    $php_install_dir/bin/phpize
    ./configure --with-php-config=$php_install_dir/bin/php-config
    make && make install
    if [ -f "`$php_install_dir/bin/php-config --extension-dir`/memcached.so" ];then
        [ -z "`grep '^extension_dir' $php_install_dir/etc/php.ini`" ] && sed -i "s@extension_dir = \"ext\"@extension_dir = \"ext\"\nextension_dir = \"`$php_install_dir/bin/php-config --extension-dir`\"@" $php_install_dir/etc/php.ini
        [ -z "`grep 'memcached.so' $php_install_dir/etc/php.ini`" ] && sed -i 's@^extension_dir\(.*\)@extension_dir\1\nextension = "memcached.so"\nmemcached.use_sasl = 1@' $php_install_dir/etc/php.ini
        echo "${CSUCCESS}PHP memcached module install successfully! ${CEND}"
        cd ..
        rm -rf memcached-$memcached_pecl_version
        [ "$Apache_version" != '1' -a "$Apache_version" != '2' ] && service php-fpm restart || service httpd restart
    else
        echo "${CFAILURE}PHP memcached module install failed, Please contact the author! ${CEND}" 
    fi
fi
cd ..
}
