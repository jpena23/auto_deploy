#!/bin/bash

# this script will:
# automate the deployment of a yelp pizza sample application from github
# install any necessary dependencies 
# configure a custom firewall
#
# NOTE: this script is built for a Linux OS CentOS/Redhat environment
# NOTE: must be ran by the root user
# by John Pena | August 24, 2015
#

if [ "$UID" != 0 ]; then
    echo "this script must be ran by the root user."
    exit 1
fi

# this function will check previous command for any errors via exit code and stop script if any are found
# in normal cases I would use this function to debug any errors
check_exit() {
    exit_code = $?
    if [ $exit_code != 0 ]; then
        echo "oops something went wrong! please check error message."
        echo "exit code: $exit_code"
        exit $exit_code
    fi
}

# list of dependencies / custom subnets / htdocs directory 
dep_list='git curl openssl php php-mysql mysql mysql-server'
sub_nets='10.0.0.0/8 192.168.0.0/16 172.0.0.0/8'
app_dir='/var/www/html/rest-api-sample-app-php'

# remove directory if it exists to start clean and avoid errors
if [ -d $app_dir ]; then
    rm -rf $app_dir
fi

mkdir $app_dir

# check if mysql is installed already, get password
val=`rpm -qa |grep mysql-server`
if [ -n "$val" ]; then
    echo -n "please enter your mysql password (default password is empty): "
    read pw
fi

# install dependencies, download paypal app setup via git, install composer
echo "installing dependencies and downloading app..."
sudo yum install $dep_list -y
git clone https://github.com/paypal/rest-api-sample-app-php $app_dir
curl -sS https://getcomposer.org/installer | php -- --install-dir=$app_dir

# run composer update
echo "updating composer..."
cd $app_dir
php composer.phar update

# start services if not yet running
echo "starting services..."
service mysqld start
service httpd start

# create database
echo "creating database..."
echo -n "please enter your mysql password (default password is empty): "
echo "create database paypal_pizza_app" | mysql -u $USER -p

# if mysql is installed already, puts in user pw, otherwise puts in default blank pw
if [ -n "$pw" ]; then
    sed -i '20s/root/$pw/' $app_dir/app/bootstrap.php
else
    sed -i '20s/root//' $app_dir/app/bootstrap.php
fi

# creating neccesary tables in mysql
cd $app_dir/install
php create_tables.php

# flush firewall rules
echo "flushing firewall rules..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

# allow ssh (port 22) / rdp (port 3389) traffic from specific subnets below
# 10.0.0.0/8, 192.168.0.0/16, 172.0.0.0/8
echo "configuring custom firewall..."
for ip in $sub_nets; do
    iptables -A INPUT -s $ip -p tcp --dport 22  -j ACCEPT
    iptables -A INPUT -s $ip -p tcp --dport 3389 -j ACCEPT
    iptables -A INPUT -s $ip -p udp --dport 3389 -j ACCEPT
done

# allow traffic over icmp and tcp ports 80 and 443 from everywhere
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT

# allow traffic over dns ports
# commented out for assignment
# iptables -A INPUT -p tcp --dport 53 -j ACCEPT
# iptables -A OUTPUT -p tcp --sport 53 -j ACCEPT
# iptables -A INPUT -p udp --dport 53 -j ACCEPT
# iptables -A OUTPUT -p udp --sport 53 -j ACCEPT

# drop anything that doesn't abide by rules above 
iptables -A INPUT -j DROP		
iptables -A OUTPUT -j DROP

echo "Finished! Paypal Pizza App Installed and Ready To Use."
echo "Navigate to http://localhost/rest-api-sample-app-php on your favorite browser."
