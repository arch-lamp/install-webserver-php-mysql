#!/usr/bin/env bash

#
# Date: 20 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used for the installation of apache web-sever and PHP 5.4. Before installation, the script will check if nginx is installed or not, if installed, script will ask the user to remove nginx or not (Note: removing nginx will also remove php-fpm if installed). Also, if the apache is already installed the script will be redirected to the main menu.
#

main() {
	clear
	echo -e "--------------------------------"
	echo -e "Installing Apache and PHP 5.4..."
	echo -e "--------------------------------"
	prerequisites
	sleep 1
	removeNginx
	sleep 1
	installApache
	sleep 1
	installPHP
	sleep 1
	makePHPinfo
	startService
	echo -e "---------------------------------------------------------------------------------------------------------"
	echo -e "Apache and PHP 5.4 successfully installed"
	echo -e "Open Browser and visit 'http://YourServerIPorAddress/info.php'. Here you will find php information on it."
	echo -e "---------------------------------------------------------------------------------------------------------"
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

removeNginx() {
	CHK_NGINX=`rpm -qa | grep nginx`
	if [ -n "$CHK_NGINX" ]; 
		then
			echo -e "Nginx already installed."
			echo -e "Do you want to remove nginx?"
			echo -e "${txtBold}Note: Removing nginx will also remove PHP if it is installed."
			echo -e "Press 'yes' to uninstall or press 'no' to exit.${txtNormal}"
			takeUserInput
			case "$USERINPUT" in
				[yY] | [yY][Ee][Ss] )
					echo -e "Removing nginx...\n--------------------"
					yum -y remove nginx >> /dev/null
					yum -y remove nginx-filesystem >> /dev/null
					echo -e "Nginx successfully removed.\n--------------------"
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
					removeNginx
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

installApache() {
	CHK_APACHE=`rpm -qa | grep httpd*`
	if [ -n "$CHK_APACHE" ]; 
		then
			echo -e "Apache is already installed.\n--------------------"
			unset CHK_APACHE
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
		else
			echo -e "Installing apache...\n--------------------"
			yum -y install httpd >> /dev/null
			unset CHK_APACHE
			CHK_APACHE=`rpm -qa | grep httpd*`
			if [ -n "$CHK_APACHE" ];
				then
					echo -e "Apache successfully installed.\n--------------------"
				else
					echo -e "Error while installing apache.\n--------------------"
				fi
	fi
}

installPHP() {
	CHK_PHP=`rpm -qa | grep php-5`
	if [ -n "$CHK_PHP" ]; 
		then
			echo -e "PHP is already installed.\n--------------------"
			unset CHK_PHP
		else
			echo -e "Installing PHP...\n--------------------"
			yum --enablerepo=remi -y install php >> /dev/null
			CHK_PHP=`rpm -qa | grep php-5`
			if [ -n "$CHK_PHP" ]; 
				then
					echo -e "PHP successfully installed.\n--------------------"
					changePHPconfiguration
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
	service httpd start >> /dev/null
	chkconfig httpd on
}

makePHPinfo() {
cat << EOF >> /var/www/html/info.php
<?php
phpinfo();
?>
EOF
}

main

