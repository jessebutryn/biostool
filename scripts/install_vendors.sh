#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Prepare racadm working directory
mkdir -p /tmp/racadm
cd /tmp/racadm


## Download - this requires a user-agent hack since Dell filters non-browser UAs
curl -fsSL -A "Mozilla/5.0 (X11; Linux x86_64; rv:10.0) Gecko/20100101 Firefox/10.0" \
    -o Dell-iDRACTools-Web-LX-11.3.0.0-795_A00.tar.gz \
    https://dl.dell.com/FOLDER12638439M/1/Dell-iDRACTools-Web-LX-11.3.0.0-795_A00.tar.gz

tar -xzvf Dell-iDRACTools-Web-LX-11.3.0.0-795_A00.tar.gz


## Workaround to add no-op systemctl, otherwise Dell's debs fail with:
##  installed srvadmin-hapi package post-installation script subprocess returned error exit status 127
## Digging further revealed the post-install script is attempting to activate a systemd service we don't care
## about (and docker doesn't do systemd.)
printf '%s\n' '#!/bin/bash' 'exit 0' >/bin/systemctl
chmod +x /bin/systemctl


## Install racadm
cd /tmp/racadm/iDRACTools/racadm

# Manually install packages to ensure proper installation
echo "Installing Dell RACADM packages..."

# Ubuntu22 doesn't have argtable2 package, so extract it from RHEL RPM
echo "Extracting libargtable2 from RHEL package..."
cd /tmp
rpm2cpio /tmp/racadm/iDRACTools/racadm/RHEL9/x86_64/srvadmin-argtable2-*.rpm | ( cd / && cpio -idmv )
ldconfig

cd /tmp/racadm/iDRACTools/racadm

# Install in correct order with verbose output
echo "Installing srvadmin-hapi..."
dpkg -i UBUNTU22/x86_64/srvadmin-hapi_*.deb

echo "Installing srvadmin-idracadm7..."
dpkg -i UBUNTU22/x86_64/srvadmin-idracadm7_*.deb

echo "Installing srvadmin-idracadm8..."
dpkg -i UBUNTU22/x86_64/srvadmin-idracadm8_*.deb || echo "Note: idracadm8 installation failed (this is optional)"

# Fix any dependency issues
echo "Fixing dependencies..."
apt-get install -f -y || true

# Run ldconfig to update library cache
echo "Updating library cache..."
ldconfig

# Verify installation
if [ -f /opt/dell/srvadmin/bin/idracadm7 ]; then
    echo "RACADM installed successfully at /opt/dell/srvadmin/bin/idracadm7"
    ldd /opt/dell/srvadmin/bin/idracadm7 | grep -i argtable || echo "Warning: libargtable2 not linked"
else
    echo "WARNING: RACADM installation may have failed - binary not found"
fi


## configure hapi dchipm.ini to avoid errors (only if racadm installed successfully)
if [ -d /opt/dell/srvadmin/etc/srvadmin-hapi/ini ]; then
    cat <<EOF >/opt/dell/srvadmin/etc/srvadmin-hapi/ini/dchipm.ini
hapi.openipmi.driverstarted=yes
hapi.openipmi.issupportedversion=yes
hapi.openipmi.driverpattern=ipmi_
hapi.openipmi.basedriverprefix=ipmi_si
hapi.openipmi.ispoweroffcapable=yes
hapi.openipmi.poweroffmodule=ipmi_poweroff
hapi.openipmi.powercyclemodule=ipmi_poweroff
hapi.openipmi.powercyclecommand=poweroff_powercycle=1
hapi.allow.user.mode=no
EOF
else
    echo "Warning: racadm directories not found, skipping dchipm.ini configuration"
fi

## Create racadm symlink (Dell installs it as idracadm7)
if [ -f /opt/dell/srvadmin/bin/idracadm7 ]; then
    ln -sf /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm
    echo "Created racadm symlink"
fi

## Cleanup
cd /tmp
rm -rf /tmp/racadm

# install supermicro sum
# Check multiple possible locations for the SUM tarball
SUM_TAR=""
if [ -f /usr/lib/sum_2.14.0_Linux_x86_64_20240215.tar.gz ]; then
    SUM_TAR="/usr/lib/sum_2.14.0_Linux_x86_64_20240215.tar.gz"
elif [ -f /opt/vendor/sum_2.14.0_Linux_x86_64_20240215.tar.gz ]; then
    SUM_TAR="/opt/vendor/sum_2.14.0_Linux_x86_64_20240215.tar.gz"
fi

if [ -n "$SUM_TAR" ]; then
    echo "Installing Supermicro SUM from $SUM_TAR"
    tar -xf "$SUM_TAR" -C /tmp/
    ln -sf /tmp/sum_2.14.0_Linux_x86_64/sum /usr/local/bin/sum
    rm -f "$SUM_TAR"
else
    echo "Warning: Supermicro SUM installer not found, skipping installation"
fi