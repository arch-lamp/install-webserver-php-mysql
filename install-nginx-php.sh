#!/usr/bin/env bash

#
# Date: 19 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used for the installation of nginx web-sever and PHP 5.4 using php-fpm. Before installation, the script will check if apache is installed or not, if installed, script will ask the user to remove apache or not (Note: removing apache will also remove PHP if installed). Also, if the nginx is already installed the script will be redirected to the main menu.
#

main() {
	clear
	echo -e "--------------------------------"
	echo -e "Installing Nginx and PHP 5.4..."
	echo -e "--------------------------------"
	prerequisites
	sleep 1
	removeHttpd
	sleep 1
	installNginx
	sleep 1
	installPHP
	sleep 1
	makePHPinfo
	startService
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "Nginx and PHP 5.4 successfully installed"
	echo -e "Open Browser and visit 'http://YourServerIPorAddress/info.php'. Here you will find php information on it."
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "Press enter to return to main menu."
	read
	sh master-install.sh
	exit 0
}

prerequisites() {
	sh install-repo.sh
	txtBold=`tput bold`
	txtNormal=`tput sgr0`
}

removeHttpd() {
	CHK_HTTPD=`rpm -qa | grep httpd`
	if [ -n "$CHK_HTTPD" ]; 
		then
			echo -e "Apache already installed."
			echo -e "Do you want to remove apache?"
			echo -e "${txtBold}Note: Removing apache will also remove PHP if it is installed."
			echo -e "Press 'yes' to uninstall or press 'no' to exit.${txtNormal}"
			takeUserInput
			case "$USERINPUT" in
				[yY] | [yY][Ee][Ss] )
					echo -e "Removing apache...\n--------------------"
					yum -y remove httpd* >> /dev/null
					echo -e "Apache successfully removed.\n--------------------"
					removePHP
				;;

				[nN] | [nN][oO] )
					echo -e "Press enter to return to the main menu."
					read
					sh master-install.sh
					exit 0	
				;;

				*)
					echo -e "${txtBold}Invalid input supplied...\nPlease choose the correct option.${txtNormal}"
					removeHttpd
				;;
			esac
		fi
}

removePHP() {
	CHK_PHP=`rpm -qa | grep php*`
	if [ -n "$CHK_PHP" ];
			then
				echo -e "Removing PHP...\n--------------------"
				yum -y remove php* >> /dev/null
				echo -e "PHP successfully removed.\n--------------------"
	fi
}

installNginx() {
	CHK_NGINX=`rpm -qa | grep nginx`
	if [ -n "$CHK_NGINX" ]; 
		then
			echo -e "Nginx is already installed.\n--------------------"
			unset CHK_NGINX
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
		else
			echo -e "Installing nginx...\n--------------------"
			yum -y install nginx >> /dev/null
			unset CHK_NGINX
			CHK_NGINX=`rpm -qa | grep nginx`
			if [ -n "$CHK_NGINX" ];
				then
					echo -e "Nginx successfully installed.\n--------------------"
				else
					echo -e "Error while installing nginx.\n--------------------"
				fi
	fi
}

installPHP() {
	CHK_PHP=`rpm -qa | grep php-fpm`
	if [ -n "$CHK_PHP" ]; 
		then
			echo -e "PHP is already installed.\n--------------------"
			unset CHK_PHP
		else
			echo -e "Installing PHP...\n--------------------"
			yum --enablerepo=remi -y install php-fpm php-cli >> /dev/null
			CHK_PHP=`rpm -qa | grep php-fpm`
			if [ -n "$CHK_PHP" ]; 
				then
					echo -e "PHP successfully installed.\n--------------------"
					changePHPconfiguration
					changeNginxConfiguration
					installPHPmodules
			fi
	fi
}

changePHPconfiguration() {
	echo -e "Changing PHP configuration...\n--------------------"
	sed -i 's#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=0#g' /etc/php.ini
	sed -i 's#;date.timezone =#date.timezone = "Asia/Kolkata"#g' /etc/php.ini
	sed -i 's/max_execution_time = [0-9]*/max_execution_time = 600/g' /etc/php.ini
	sed -i 's/max_input_time = [0-9]*/max_input_time = 600/g' /etc/php.ini
	sed -i 's/memory_limit = [0-9]*M/memory_limit = 256M/g' /etc/php.ini
	sed -i 's/post_max_size = [0-9]*M/post_max_size = 25M/g' /etc/php.ini
	sed -i 's/upload_max_filesize = [0-9]*M/upload_max_filesize = 20M/g' /etc/php.ini
	sed -i 's/max_file_uploads = [0-9]*/max_file_uploads = 20/g' /etc/php.ini
	echo -e "Configuration successfully changed.\n--------------------"
}

changeNginxConfiguration() {
	mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
	cp nginx.conf /etc/nginx/conf.d/default.conf
}

installPHPmodules() {
	echo -e "Do you want to install the following PHP modules?"
	echo -e "php-mysql\nphp-gd\nphp-imap\nphp-pear\nphp-xml\nphp-xmlrpc\nphp-mbstring\nphp-mcrypt\nphp-tidy\n"
	echo -e "Press 'yes' to continue or press 'no' to exit."
	takeUserInput
	case "$USERINPUT" in
		[yY] | [yY][Ee][Ss] )
			echo -e "Please wait while we are installing the modules...\n--------------------"
			yum --enablerepo=remi -y install php-mysql php-gd php-imap php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-tidy >> /dev/null
			echo -e "Modules successfully installed...\n--------------------"
		;;
		[nN] | [nN][oO] )
			echo -e "";
		;;

		*)
			echo -e "${txtBold}Invalid input supplied...\nPlease choose the correct option.${txtNormal}"
			installPHPmodules
		;;
	esac

}

takeUserInput() {
	unset "USERINPUT"
	read -e USERINPUT
	if [[ -z "$USERINPUT" ]]; 
		then
			echo -e "${txtBold}Please choose at least one option...\n${txtNormal}"
			takeUserInput
	fi
}

startService() {
	service nginx start >> /dev/null
	chkconfig nginx on
	service php-fpm start >> /dev/null
	chkconfig php-fpm on
}

makePHPinfo() {
cat << EOF >> /usr/share/nginx/html/info.php
<?php
phpinfo();
?>
EOF
}

main

