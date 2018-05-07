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

# Install AWS agent
cd /root
mkdir -p aws_agent >> /root/install-log.txt 2>&1
cd aws_agent >> /root/install-log.txt 2>&1
wget https://d1wk0tztpsntt1.cloudfront.net/linux/latest/install
chmod 744 install >> /root/install-log.txt 2>&1
bash install >> /root/install-log.txt 2>&1

# Install tools to manage SELinux
yum -y install selinux-policy selinux-policy-targeted policy policycoreutils-python setools tree >> /root/selinux-tools-log.txt 2>&1

# Create SSH users group
groupadd -g 505 sshusers
usermod -a -G sshusers ec2-user
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
printf "\n" >> /etc/ssh/sshd_config
printf "# Make an allowance for sshusers; C. Birmingham II" >> /etc/ssh/sshd_config
printf "\nAllowGroups sshusers" >> /etc/ssh/sshd_config
sed -i 's/PermitRootLogin forced-commands-only/#PermitRootLogin forced-commands-only/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
/etc/init.d/sshd restart >> /root/install-log.txt 2>&1

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

# Install php
 yum -y install php56 >> /root/install-log.txt 2>&1
 yum -y install php56-mysqlnd >> /root/install-log.txt 2>&1
 yum -y install php56-mbstring >> /root/install-log.txt 2>&1
 service httpd restart >> /root/install-log.txt 2>&1

 #Install git
 yum -y install git

 #Clone Coral
 cd /var/www
 git clone https://github.com/coral-erm/coral.git
 mv coral html
 cd html
 chmod -R apache:apache *
