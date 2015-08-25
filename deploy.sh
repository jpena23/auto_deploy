#!/bin/bash

# this script will:
# automate the deployment of a yelp pizza sample application from github
# install any necessary dependencies 
# configure a custom firewall
#
# NOTE: this script is built for a Linux OS CentOS/Redhat environment 
# by John Pena | August 24, 2015
#

# this function will check for exit code and break out upon error
check_exit() {
    exit_code = $?
    if [ $exit_code != 0 ]; then
        echo "oops something went wrong! please check error message."
        echo "exit code: $exit_code"
        exit $exit_code
    fi
}

# list of dependencies / htdocs directory
dep_list='git curl openssl php php-mysql mysql mysql-server'
app_dir="/var/www/html/rest-api-sample-app-php"

# remove directory if it exists to start clean and avoid errors
if [ -d $app_dir ]; then
    rm -rf $app_dir
fi

mkdir $app_dir

# check if mysql is installed already, get password
val=`rpm -qa |grep mysql-server`
if [ -n $val ]; then
    echo -n "please enter your mysql password: "
    read pw
fi

# flush firewall rules
echo "flushing firewall rules..."
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X 

# install dependencies, download paypal app setup via git
echo "installing dependencies and downloading app..."
sudo yum install $dep_list -y
git clone https://github.com/paypal/rest-api-sample-app-php $app_dir
curl -sS https://getcomposer.org/installer | php -- --install-dir=$app_dir

# run update composer
echo "updating composer..."
cd $app_dir/rest-api-sample-app-php
php composer.phar update

# start services if not yet running
echo "starting services..."
service mysqld start
service httpd start

# create database
echo "creating database..."
echo "please enter your MYSQL password (default password is empty)..."
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

echo "Finished! Paypal Pizza App Installed and Ready To Use."
