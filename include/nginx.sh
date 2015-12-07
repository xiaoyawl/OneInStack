#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Project home page:
#       http://oneinstack.com
#       https://github.com/lj2007331/oneinstack

Install_Nginx()
{
cd $oneinstack_dir/src
src_url=http://downloads.sourceforge.net/project/pcre/pcre/$pcre_version/pcre-$pcre_version.tar.gz && Download_src
src_url=http://nginx.org/download/nginx-$nginx_version.tar.gz && Download_src

tar xzf pcre-$pcre_version.tar.gz
cd pcre-$pcre_version
./configure
make -j `awk '/processor/{i++}END{print i}' /proc/cpuinfo` && make install
cd ..

id -u $run_user >/dev/null 2>&1
[ $? -ne 0 ] && useradd -M -s /sbin/nologin $run_user 

wget http://geolite.maxmind.com/download/geoip/api/c/GeoIP.tar.gz
tar xf GeoIP.tar.gz
cd GeoIP-1.4.8
./configure
make -j `awk '/processor/{i++}END{print i}' /proc/cpuinfo` && make install
echo '/usr/local/lib' > /etc/ld.so.conf.d/geoip.conf
ldconfig
#wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
#gunzip GeoIP.dat.gz
cd ..

nginx_Add_mode(){
	modeName=(ngx_http_google_filter_module ngx_http_substitutions_filter_module ngx-fancyindex)
	Author=(cuber yaoweibin aperezdc)
	for i in `seq 1 ${#modeName[@]}`;do
		[ "$i" = "1" ] && j=0
		git clone https://github.com/${Author[$j]}/${modeName[$j]}.git
		[ "$i" = "1" ] && nginxAddMode="--add-module=../${modeName[$j]}" || nginxAddMode="--add-module=../${modeName[$j]} $nginxAddMode"
		let j++
	done
}

nginx_Add_mode && [ "$?" != "0" ] && nginxAddMode=""
nginxAddMode="--with-http_mp4_module --with-http_gunzip_module --with-http_image_filter_module --with-http_addition_module $nginxAddMode"

tar xzf nginx-$nginx_version.tar.gz
cd nginx-$nginx_version
# Modify Nginx version
#sed -i 's@#define NGINX_VERSION.*$@#define NGINX_VERSION      "1.2"@' src/core/nginx.h
#sed -i 's@#define NGINX_VER.*NGINX_VERSION$@#define NGINX_VER          "Linuxeye/" NGINX_VERSION@' src/core/nginx.h
#sed -i 's@Server: nginx@Server: linuxeye@' src/http/ngx_http_header_filter_module.c

# close debug
sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

if [ "$je_tc_malloc" == '1' ];then
    malloc_module="--with-ld-opt='-ljemalloc'"
elif [ "$je_tc_malloc" == '2' ];then
    malloc_module='--with-google_perftools_module'
    mkdir /tmp/tcmalloc
    chown -R ${run_user}.$run_user /tmp/tcmalloc
fi

[ ! -d "$nginx_install_dir" ] && mkdir -p $nginx_install_dir
#./configure --prefix=$nginx_install_dir --user=$run_user --group=$run_user --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-ipv6 --with-http_gzip_static_module --with-http_realip_module --with-http_flv_module $malloc_module
./configure --prefix=$nginx_install_dir --user=$run_user --group=$run_user --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-ipv6 --with-http_gzip_static_module --with-http_realip_module --with-http_flv_module $malloc_module ${nginxAddMode}
make -j `awk '/processor/{i++}END{print i}' /proc/cpuinfo` && make install
if [ -e "$nginx_install_dir/conf/nginx.conf" ];then
    cd ..
    rm -rf nginx-$nginx_version
    echo "${CSUCCESS}Nginx install successfully! ${CEND}"
else
    rm -rf $nginx_install_dir
    echo "${CFAILURE}Nginx install failed, Please Contact the author! ${CEND}" 
    kill -9 $$
fi

[ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$nginx_install_dir/sbin:\$PATH" >> /etc/profile 
[ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $nginx_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$nginx_install_dir/sbin:\1@" /etc/profile
. /etc/profile

OS_CentOS='/bin/cp ../init.d/Nginx-init-CentOS /etc/init.d/nginx \n
chkconfig --add nginx \n
chkconfig nginx on'
OS_Debian_Ubuntu='/bin/cp ../init.d/Nginx-init-Ubuntu /etc/init.d/nginx \n
update-rc.d nginx defaults'
OS_command
cd ..

sed -i "s@/usr/local/nginx@$nginx_install_dir@g" /etc/init.d/nginx

mv $nginx_install_dir/conf/nginx.conf{,_bk}
if [[ $Apache_version =~ ^[1-2]$ ]];then
    /bin/cp config/nginx_apache.conf $nginx_install_dir/conf/nginx.conf
elif [[ $Tomcat_version =~ ^[1-2]$ ]] && [ ! -e "$php_install_dir/bin/php" ];then
    /bin/cp config/nginx_tomcat.conf $nginx_install_dir/conf/nginx.conf
else
    /bin/cp config/nginx.conf $nginx_install_dir/conf/nginx.conf
    [ "$PHP_yn" == 'y' ] && [ -z "`grep '/php-fpm_status' $nginx_install_dir/conf/nginx.conf`" ] &&  sed -i "s@index index.html index.php;@index index.html index.php;\n    location ~ /php-fpm_status {\n        #fastcgi_pass remote_php_ip:9000;\n        fastcgi_pass unix:/dev/shm/php-cgi.sock;\n        fastcgi_index index.php;\n        include fastcgi.conf;\n        allow 127.0.0.1;\n        deny all;\n        }@" $nginx_install_dir/conf/nginx.conf
fi
cat > $nginx_install_dir/conf/proxy.conf << EOF
proxy_connect_timeout 300s;
proxy_send_timeout 900;
proxy_read_timeout 900;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_redirect off;
proxy_hide_header Vary;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer \$http_referer;
proxy_set_header Cookie \$http_cookie;
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF
sed -i "s@/data/wwwroot/default@$wwwroot_dir/default@" $nginx_install_dir/conf/nginx.conf
sed -i "s@/data/wwwlogs@$wwwlogs_dir@g" $nginx_install_dir/conf/nginx.conf
sed -i "s@^user www www@user $run_user $run_user@" $nginx_install_dir/conf/nginx.conf
[ "$je_tc_malloc" == '2' ] && sed -i 's@^pid\(.*\)@pid\1\ngoogle_perftools_profiles /tmp/tcmalloc;@' $nginx_install_dir/conf/nginx.conf 

# logrotate nginx log
cat > /etc/logrotate.d/nginx << EOF
$wwwlogs_dir/*nginx.log {
daily
rotate 5
missingok
dateext
compress
notifempty
sharedscripts
postrotate
    [ -e /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
endscript
}
EOF

ldconfig
service nginx start
}
