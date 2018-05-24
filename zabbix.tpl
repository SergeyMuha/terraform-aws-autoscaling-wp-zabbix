#! /bin/bash
wget http://repo.zabbix.com/zabbix/3.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.4-1+trusty_all.deb
sudo dpkg -i zabbix-release_3.4-1+trusty_all.deb
sudo apt-get update 
sudo apt-get install -y debconf-utils
export DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password qwerty"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password qwerty"

sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-agent -y

mysql -u root -pqwerty -e "create database zabbix character set utf8 collate utf8_bin; GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost IDENTIFIED BY 'qwerty'"

zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -pqwerty zabbix

sudo sed -i 's/# DBPassword=/DBPassword=qwerty/g' /etc/zabbix/zabbix_server.conf

sudo service zabbix-server start

sudo update-rc.d zabbix-server enable

sudo sed -i  's/post_max_size = 8M/post_max_size = 16M/g' /etc/php5/apache2/php.ini
sudo sed -i  's/max_input_time = 60/post_max_size = 300/g' /etc/php5/apache2/php.ini
sudo sh -c ' echo "max_execution_time = 300" >> /etc/php5/apache2/php.ini'
sudo sed -i  's/;date.timezone =/date.timezone = Europe\/Minsk/g' /etc/php5/apache2/php.ini
sudo sed -i  's/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Minsk/g' /etc/zabbix/apache.conf

service apache2 restart

wget https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/3.4.9/zabbix-3.4.9.tar.gz
tar -zxvf zabbix-3.4.9.tar.gz

sudo mkdir  /var/www/html/zabbix
cd zabbix-3.4.9/frontends/php/
sudo cp -a . /var/www/html/zabbix/

sudo sh -c " sed 's/DocumentRoot \/var\/www\/html/\DocumentRoot \/var\/www\/html\/zabbix/' /etc/apache2/sites-available/000-default.conf > /etc/apache2/sites-available/zabbix.conf"
sudo a2dissite 000-default.conf
sudo a2ensite zabbix.conf
sudo service apache2 reload
sudo chown -R www-data:www-data /var/www/html/zabbix/
sudo service apache2 restart


