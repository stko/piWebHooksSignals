
##### To install piWebHooksSignals, get a virgin raspian lite image from raspberry.org
# tested on raspian stretch
#  boot the virgin raspian image, login
#  do 'export DEBUG=YES' first, if the finished image shall not become read-only. This is good for debugging, but bad for daily use..
#
# start the install script with
#    bash <(curl -s https://raw.githubusercontent.com/stko/piWebHooksSignals/master/install.sh)
# and spent some hours with your friends or family. When you are back,
# the installation should be done

echo "The piWebHooksSignals Installer starts"
cd

sudo apt-get update --assume-yes
sudo apt-get install --assume-yes \
ppp wvdial \
joe \
python3-pip \
usbmount \
python3-gpiozero \
 python3-requests \
python-rpi.gpio python3-rpi.gpio 

if [ -z ${DEBUG+x} ] && false ; then
## begin unisonfs overlay file system (http://blog.pi3g.com/2014/04/make-raspbian-system-read-only/)

### Do we need to disable swap?? actual not..

# dphys-swapfile swapoff
# dphys-swapfile uninstall
# update-rc.d dphys-swapfile disable
sudo apt-get  --assume-yes install unionfs-fuse

# Create mount script

cat << 'EOF' | sudo tee /usr/local/bin/mount_unionfs
#!/bin/sh
DIR=$1
ROOT_MOUNT=$(awk '$2=="/" {print substr($4,1,2)}' < /etc/fstab)
if [ $ROOT_MOUNT = "rw" ]
then
	/bin/mount --bind ${DIR}_org ${DIR}
else
	/bin/mount -t tmpfs ramdisk ${DIR}_rw
	/usr/bin/unionfs-fuse -o cow,allow_other,suid,dev,nonempty ${DIR}_rw=RW:${DIR}_org=RO ${DIR}
fi
EOF

# make it executable:

sudo chmod +x /usr/local/bin/mount_unionfs
 ## see the directory renaming at the end of this installation script

## end unisonfs overlay file system
fi

# Read-Only Image instructions thankfully copied from https://kofler.info/raspbian-lite-fuer-den-read-only-betrieb/

# remove packs which do need writable partitions
sudo apt-get remove --purge --assume-yes cron logrotate triggerhappy dphys-swapfile fake-hwclock samba-common
sudo apt-get autoremove --purge --assume-yes
#fi

wget  https://github.com/stko/piWebHooksSignals/archive/master.zip -O piWebHooksSignals.zip && unzip piWebHooksSignals.zip
mv piWebHooksSignals-master piWebHooksSignals
sudo mkdir /etc/piWebHooksSignals
sudo cp piWebHooksSignals/scripts/sample_* /etc/piWebHooksSignals/
sudo rename 's/sample_//' /etc/piWebHooksSignals/sample*

chmod a+x /home/pi/piWebHooksSignals/scripts/*.sh


# start to make the system readonly
sudo rm -rf /var/lib/dhcp/ /var/spool /var/lock
sudo ln -s /tmp /var/lib/dhcp
sudo ln -s /tmp /var/spool
sudo ln -s /tmp /var/lock
if [ -f /etc/resolv.conf ]; then
	sudo mv /etc/resolv.conf /tmp/resolv.conf
fi
sudo ln -s /tmp/resolv.conf /etc/resolv.conf

# add the temporary directories to the mountlist
cat << 'MOUNT' | sudo tee /etc/fstab
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    ro,defaults          0       2
/dev/mmcblk0p2  /               ext4    ro,defaults,noatime  0       1
# a swapfile is not a swap partition, no line here
#   use  dphys-swapfile swap[on|off]  for that
tmpfs	/var/log	tmpfs	nodev,nosuid	0	0
tmpfs	/var/tmp	tmpfs	nodev,nosuid	0	0
tmpfs	/tmp	tmpfs	nodev,nosuid	0	0
#/dev/sda1       /media/usb0     vfat    ro,defaults,nofail,x-systemd.device-timeout=1   0       0


MOUNT

if [ -z ${DEBUG+x} ] && false ; then
# add the unison directories to the mountlist
cat << 'MOUNT' | sudo tee --append /etc/fstab
mount_unionfs   /etc            fuse    defaults          0       0
mount_unionfs   /var            fuse    defaults          0       0

MOUNT

fi 

#add boot options
echo -n " fastboot noswap" | sudo tee --append /boot/cmdline

#fi


# create the GSM-stick settings
# taken from https://raspberry.tips/raspberrypi-tutorials/usb-surfstick-am-raspberry-pi-verwenden-mobiles-internet

# do we need eventually 'sudo wvdialconf /etc/wvdial.conf' first?

cat << 'WVDIAL' | sudo tee --append /etc/wvdial.conf

[Dialer gsmstick]
Modem = /dev/ttyUSB0
Auto DNS = on
Init3 = AT+CGDCONT=1,"IP","webmobil1"
Stupid mode = on
Phone = *99#
ISDN = 0
Auto Reconnect = on
Baud = 460800
Username="blank"
Password="blank"
WVDIAL

cat << 'WVDIAL' | sudo tee --append /etc/ppp/peers/wvdial
defaultroute
replacedefaultroute
WVDIAL

cat << 'WVDIAL' | sudo tee --append /etc/network/interfaces
auto ppp0
iface ppp0 inet wvdial
provider gsmstick
WVDIAL




# set the magic power off Pin at poweroff
echo  "dtoverlay=gpio-poweroff,gpiopin=22" | sudo tee --append /boot/config.txt

# setting up the systemd services
# very helpful source : http://patrakov.blogspot.de/2011/01/writing-systemd-service-files.html

cat << 'EOF' | sudo tee  /etc/systemd/system/fireWebHooks.service
[Unit]
Description=Goes through the configured list of webhooks and tries to trigger them
Wants=network-online.target piWebHooksMaster.service
After=network.target network-online.target 


[Service]
ExecStart=/home/pi/piWebHooksSignals/scripts/fireWebHooks.sh

[Install]
WantedBy=default.target
EOF


cat << 'EOF' | sudo tee  /etc/systemd/system/piWebHooksMaster.service
[Unit]
Description=piWebHooksSignals Main Server
Wants=network.target
After=network.target
Before=fireWebHooks.service

[Service]
ExecStart=/home/pi/piWebHooksSignals/scripts/piWebHooksMaster.sh 
Restart=on-failure

[Install]
WantedBy=default.target

EOF


sudo systemctl enable fireWebHooks 
sudo systemctl enable piWebHooksMaster

#echo "Your actual config"
#sudo nano /etc/piWebHooksSignals/settings.ini


#### disable unison settings
#  if [ -z ${DEBUG+x} ]; then
#  	#Prepare unisonfs  directories
#  	sudo cp -al /etc /etc_org
#  	sudo mv /var /var_org
#  	sudo mkdir /etc_rw
#  	sudo mkdir /var /var_rw
#  fi

#PS3='Please take your choice: '
#options=("show config" "edit config" "Quit")
#select opt in "${options[@]}"
#	do
#		case $opt in
#			"show config")
#				more /etc/piWebHooksSignals/settings.ini
#
#			;;
#			"edit config")
#				sudo nano /etc/piWebHooksSignals/settings.ini
#
#			;;
#			"Quit")
#				break
#			;;
#			*) echo invalid option;;
#		esac
#	done

cat << 'EOF'
Installation finished

SSH is enabled and the default password for the 'pi' user has not been changed.
This is a security risk - please login as the 'pi' user and type 'passwd' to set a new password."

Also this is the best chance now if you want to do some own modifications,
as with the next reboot the image will be write protected

if done, end this session with
 
     sudo halt

and your piWebHooksSignals all-in-one is ready to use

have fun :-)

the piWebHooksSignals team
EOF

sync
sync
sync

