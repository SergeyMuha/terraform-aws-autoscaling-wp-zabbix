#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install apache2 -y
sudo apt-get install php5 php5-mysql libapache2-mod-php5  php5-cli php5-cgi php5-gd -y
sudo apt-get install mysql-server-5.5 -y

cd /home/ubuntu
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
sudo mkdir /var/www/html/wordpress

sudo /usr/local/bin/wp core download --allow-root --path=/var/www/html/wordpress

sudo /usr/local/bin/wp core config --dbhost="${databasedns}" --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --allow-root --path=/var/www/html/wordpress

a="${lbdns}" && sudo /usr/local/bin/wp core install --url="$a" --title="Blog Title" --admin_user="admin" --admin_password="wordpress" --admin_email="email@domain.com" --allow-root --path=/var/www/html/wordpress

sudo sh -c " sed 's/DocumentRoot \/var\/www\/html/\DocumentRoot \/var\/www\/html\/wordpress/' /etc/apache2/sites-available/000-default.conf > /etc/apache2/sites-available/wordpress.conf"

sudo a2dissite 000-default.conf
sudo a2ensite wordpress.conf
sudo service apache2 reload
sudo chown -R www-data:www-data /var/www/html/wordpress/
sudo service apache2 restart


echo "${databasedns}" > /tmp/iplist
echo "${lbdns}" >> /tmp/iplist 
echo "${zabbixip}" >> /tmp/iplist
sudo apt-get update

sudo apt-get install zabbix-agent -y

sudo sed -i 's/ServerActive=127.0.0.1/ServerActive=${zabbixip}/g'  /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/Server=127.0.0.1/Server=${zabbixip}/g'  /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/Hostname=Zabbix server/Hostname=${zabbixdns}/g'  /etc/zabbix/zabbix_agentd.conf


sudo service zabbix-agent stop
sudo service zabbix-agent start

