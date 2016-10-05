#!/bin/bash -v
#
# This file was auto-generated by gen-all-dockerfiles.sh; do not modify manually.
#
# ./sdno-service-mss/init-mysql.sh
#

# Start mysql
su mysql -c /usr/bin/mysqld_safe &

# Wait for mysql to initialize; Set mysql root password
for i in {1..10}; do
    /usr/bin/mysqladmin -u root password 'rootpass' && break
    echo sleep $i
    sleep $i
done
