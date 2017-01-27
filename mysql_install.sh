#!/bin/bash
#  	exit code
# exit 29 tar file error
# exit 30 yum error
# exit 31 depending install error
# exit 32 confingure error
# exit 33 cmake error
# exit 34 make install error


# static variable
#static varlable
NULL=/dev/null
INSTALL_TAR_FILE="mysql-5.6.25.tar.gz"
DEPEND_SOFTWARE="gcc* cmake ncurses-devel perl"

#function
test_yum () {
	yum clean all &> $NULL
	repolist=$(yum repolist | awk  '/repolist:.*/{print $2}' | sed 's/,//')
	if [ $repolist -gt 0 ];then
		return 0
	fi
	return 1
}

print_info () {
	if [ -n "$1" ] && [ -n "$2" ] ;then
		case "$2" in 
		OK)
			echo -e "$1 \t\t\t \e[32;1m[OK]\e[0m"
			;;
		Fail)
			echo -e "$1 \t\t\t \e[31;1m[Fail]\e[0m"
			;;
		*)
			echo "Usage info {OK|Fail}"
		esac
	fi
}

rotate_line(){
	INTERVAL=0.1
	TCOUNT="0"
	while :
	do
		TCOUNT=`expr $TCOUNT + 1`
		case $TCOUNT in
		"1")
			echo -e '-'"\b\c"
			sleep $INTERVAL
			;;
		"2")
			echo -e '\\'"\b\c"
			sleep $INTERVAL
			;;
		"3")
			echo -e "|\b\c"
			sleep $INTERVAL
			;;
		"4")
			echo -e "/\b\c"
			sleep $INTERVAL
			;;
		*)
			TCOUNT="0";;
		esac
	done
}

test_yum
if [ $? -ne 0 ];then
	print_info "Yum error." "Fail"
	exit 30
fi

rotate_line &
disown $!
yum -y install $DEPEND_SOFTWARE > $NULL
result=$?
kill -9 $!

if [ $? -ne 0 ];then
	print_info "depend software install" "Fail"
	exit 31
else 
	print_info "depend software install" "OK"
fi

grep mysql /etc/passwd &> $NULL
if [ $? -ne 0 ];then
	useradd -s /sbin/nologin/ mysql
fi

if [ ! -f $INSTALL_TAR_FILE ];then
	exit 29	
fi

SOURCE_DIR=$(tar -tf $INSTALL_TAR_FILE | head -1)
#echo "Source_Dir=$SOURCE_DIR"
rotate_line &
disown $!
tar -xf $INSTALL_TAR_FILE > $NULL
result=$?
kill -9 $!
[ $result -ne 0 ] && print_info "tar error"  && exit 29

cd $SOURCE_DIR
[ -d cmake ] || print_info "cmake no such dir." "Fail" || exit 33
rotate_line &
disown $!
cmake . > $NULL
result=$?
kill -9 $!
[ $result -ne 0 ] && print_info "cmake error." "Fail" &&  exit 33

rotate_line &
disown $!
make > $NULL
make install > $NULL
result=$?
kill -9 $!
[ $result -ne 0 ] && print_info "make && make install error." "Fail" && exit 34

mysql_install_dir=/usr/local/mysql/
[ -d $mysql_install_dir ] && print_info "mysql install" "OK"

#安装完成后还需要进行相应文件的配置，以便与后续使用
#ln -s /usr/local/mysql/bin/* /bin/  &> $NULL
/usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/usr/local/mysql/data/ --basedir=/usr/local/mysql/ &>$NULL
chown -R root.mysql /usr/local/mysql
chown -R mysql /usr/local/mysql/data
/bin/cp -f /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
/bin/cp -f /usr/local/mysql/support-files/my-default.cnf /etc/my.cnf

grep "/usr/local/mysql/lib/" /etc/ld.so.conf &> $NULL
if [ $? -ne 0 ];then
	echo "/usr/local/mysql/lib/" >> /etc/ld.so.conf
	ldconfig
fi

grep "/usr/local/mysql/bin/" /etc/profile &> $NULL
if [ $? -eq 0 ];then
	exit 0
fi

cat >> /etc/profile << EOF
PATH=\$PATH:/usr/local/mysql/bin/
export PATH
EOF
