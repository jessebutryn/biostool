#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Install Dell racadm and OpenManage tools
echo 'deb http://linux.dell.com/repo/community/openmanage/950/focal focal main' >> /etc/apt/sources.list.d/linux.dell.com.sources.list
curl -Ss https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc -o 0x1285491434D8786F.asc
apt-key add 0x1285491434D8786F.asc
dpkg --configure -a
apt-get update
apt-get install -y srvadmin-hapi
printf '%s\n' '#!/bin/sh' '/bin/true' > /var/lib/dpkg/info/srvadmin-hapi.postinst
apt-get install -y srvadmin-hapi srvadmin-idracadm7
sed -i 's/systemctl.*/:/g' /var/lib/dpkg/info/srvadmin-idracadm7.postinst
apt-get install -y srvadmin-all
sed -i 's/systemctl.*/:/g' /var/lib/dpkg/info/srvadmin-idracadm8.postinst
chmod +x /opt/dell/srvadmin/sbin/racadm
ln -s /opt/dell/srvadmin/sbin/racadm /usr/local/bin

## Install Supermicro SUM tool
tar -xf /usr/lib/sum_2.14.0_Linux_x86_64_20240215.tar.gz -C /tmp/
ln -s /tmp/sum_2.14.0_Linux_x86_64/sum /usr/local/bin
rm /usr/lib/sum_2.14.0_Linux_x86_64_20240215.tar.gz
