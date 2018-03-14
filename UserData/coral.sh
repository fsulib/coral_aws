# Save build parameters
echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
echo "CoralDatabaseUser: ${CORAL_DATABASE_USER}" >> /root/build-params.txt
echo "CoralDatabasePass: ${CORAL_DATABASE_PASS}" >> /root/build-params.txt
echo "CoralAdminUser: ${CORAL_ADMIN_USER}" >> /root/build-params.txt
echo "CoralAdminPass: ${CORAL_ADMIN_PASS}" >> /root/build-params.txt
echo "CoralAdminEmail: ${CORAL_ADMIN_EMAIL}" >> /root/build-params.txt
echo "CoralSiteName: ${CORAL_SITE_NAME}" >> /root/build-params.txt
echo "CustomShScriptUrl: ${CUSTOM_SH_SCRIPT_URL}" >> /root/build-params.txt

# Mount external devices 
mkfs -t ext4 /dev/xvdb
mkfs -t ext4 /dev/xvdc
cp -pr /var /tmp
cp -pr /home /tmp 
mount /dev/xvdb /var
mount /dev/xvdc /home
cp -pr /etc/fstab /etc/fstab.orig
echo "/dev/xvdb   /var        ext4    defaults,nofail 0   2" >> /etc/fstab
echo "/dev/xvdc   /home       ext4    defaults,nofail 0   2" >> /etc/fstab
mount -a
cp -prT /tmp/var /var
cp -prT /tmp/home /home
rm -rf /tmp/var
rm -rf /tmp/home

# Set timezone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Run updates
yum -y update > /root/updates.txt

# Install Apache
yum -y install httpd24 > /root/install-log.txt 2>&1
service httpd start >> /root/install-log.txt 2>&1
chkconfig httpd on >> /root/install-log.txt 2>&1

# Install mysql
yum -y install mysql-server >> /root/install-log.txt 2>&1
chkconfig mysqld on >> /root/install-log.txt 2>&1
service mysqld start >> /root/install-log.txt 2>&1
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${DATABASE_ROOT_PASS}') WHERE User = 'root'" >> /root/install-log.txt 2>&1
mysql -e "DROP USER ''@'localhost'" >> /root/install-log.txt 2>&1
mysql -e "DROP USER ''@'$(hostname)'" >> /root/install-log.txt 2>&1
mysql -e "DROP DATABASE test" >> /root/install-log.txt 2>&1
mysql -e "FLUSH PRIVILEGES" >> /root/install-log.txt 2>&1