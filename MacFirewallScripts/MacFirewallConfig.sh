#! /bin/bash
# Back Up files first
sudo mv /etc/pf.conf /etc/pf.conf_backup_$(date +%F)
sudo mv /etc/pf.anchors/gcforwarding.conf /etc/pf.anchors/gcforwarding.conf_backup_$(date +%F)
# Move the files from the Desktop to their new location
sudo cp -f ./pf.conf /etc/pf.conf
sudo cp -f ./com.apple.pfctl.plist /Library/LaunchDaemons/com.apple.pfctl.plist
sudo cp -f ./gcforwarding.conf /etc/pf.anchors/gcforwarding.conf
# Give them the correct Permission
cd /etc
sudo chmod 644 pf.conf
sudo chown root pf.conf
sudo chgrp wheel pf.conf
ls -ll pf.conf

cd /etc/pf.anchors
sudo chmod 644 gcforwarding.conf
sudo chown root gcforwarding.conf
sudo chgrp wheel gcforwarding.conf
ls -ll gcforwarding.conf

cd /Library/LaunchDaemons
sudo chmod 644 com.apple.pfctl.plist
sudo chown root com.apple.pfctl.plist
sudo chgrp wheel com.apple.pfctl.plist
ls -ll com.apple.pfctl.plist

sudo pfctl -f /etc/pf.conf

echo Finished
