#!/bin/bash

NULL=/dev/null
mysql_rpm="MySQL-5.6.rpm.tar" 

test_yum(){

    yum clean all > $NULL
    yum_list=$(yum repolist | awk -F: '/repolist/{print $2}'  | sed 's/,//')
    if [ $yum_list -gt 0 ];then
        return 0
    else
        return 1
        exit 3
    fi  
}

test_yum
yum -y install mysql-server mysql > $NULL
service mysqld start > $NULL
service mysqld stop  > $NULL
rm -rf /var/lib/mysql
rm -rf /etc/my.cnf
rpm -e --nodeps mysql-server
rpm -e --nodeps mysql-libs
rpm -Uvh MySQL-*
