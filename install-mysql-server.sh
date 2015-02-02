#!/usr/bin/env bash

#
# Date: 20 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used for the installation of MySQL Server. Before installation, the script will check if it is installed or not, if installed, the script will be redirected to the main menu.
#

main() {
	clear
	echo -e "--------------------------"
	echo -e "Installing MySQL Server..."
	echo -e "--------------------------"
	prerequisites
	sleep 1
	installMySQLServer
	sleep 1
	restartServices
	echo -e "--------------------------------------"
	echo -e "MySQL Server successfully installed."
	echo -e "--------------------------------------"
	echo -e "Press enter to return to the main menu."
	read
	sh master-install.sh
	exit 0
}

prerequisites() {
	sh install-repo.sh
	txtBold=`tput bold`
	txtNormal=`tput sgr0`
}

installMySQLServer() {
	CHK_MYSQL=`rpm -qa | grep mysql-server`
	if [[ -n "$CHK_MYSQL" ]]; 
		then
			echo -e "MySQL Server is already installed.\n--------------------"
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
		else
			yum --enablerepo=remi -y install mysql-server mysql >> /dev/null
			unset CHK_MYSQL
			CHK_MYSQL=`rpm -qa | grep mysql-server`
			if [[ -n "$CHK_MYSQL" ]]; 
				then
					echo -e "MySQL secure installation started...\n--------------------"
					startServices
					sleep 1
					mysql_secure_installation
					echo -e "MySQL secure installation completed.\n--------------------"
				else
					echo -e "Error while installing MySQL Server.\n--------------------"
					echo -e "Press enter to return to the main menu."
					read
					sh master-install.sh
					exit 0
			fi
	fi
}

startServices() {
	service mysqld start >> /dev/null
}

restartServices() {
	service mysqld restart >> /dev/null
}

main

