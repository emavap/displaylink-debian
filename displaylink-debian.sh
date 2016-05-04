#!/bin/bash
#
# DisplayLink driver installer for Debian GNU/Linux
#
# Copyleft: Adnan Hodzic <adnan@hodzic.org>
# License: GPLv3

version=1.0.335
driver_dir=$version

# Dependencies
deps=(unzip linux-headers-$(uname -r) dkms lsb-release)

dep_check() {
   echo "Checking dependencies..."
   for dep in ${deps[@]}
   do
      if ! dpkg -s $dep > /dev/null 2>&1
      then
	 read -p "$dep not found! Install? [y/N] " response
	 response=${response,,} # tolower
	 if [[ $response =~ ^(yes|y)$ ]]
	 then
	    if ! sudo apt-get install $dep
	    then
	       echo "$dep installation failed.  Aborting."
	       exit 1
	    fi
	 else
	    echo "Cannot continue without $dep.  Aborting."
	    exit 1
	 fi
      else
	 echo "$dep is installed"
      fi
   done
}

distro_check(){

# RedHat
if [ -f /etc/redhat-release ];
then
	echo "This is a Redhat based distro ..."
	# ToDo:
	# Add platform type message for RedHat
	exit 1
else

# Confirm dependencies are in place
dep_check

# Checker parameters 
lsb="$(lsb_release -is)"
codename="$(lsb_release -cs)"
platform="$(lsb_release -ics | sed '$!s/$/ /' | tr -d '\n')"

# Unsupported platform message
message(){
echo -e "\n------------------------------------------------------\n"
echo -e "Unsuported platform: $platform"
echo -e ""
echo -e "This tool is Open Source and feel free to extend it"
echo -e "GitHub repo: https://goo.gl/6soXDE"
echo -e "\n------------------------------------------------------\n"
}

# Ubuntu
if [ "$lsb" == "Ubuntu" ];
then
	if [ $codename == "trusty" ] || [ $codename == "vivid" ] || [ $codename == "wily" ] || [ $codename == "xenial" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
	else
		message
		exit 1
	fi
# Elementary
elif [ "$lsb" == "elementary OS" ];
then
    if [ $codename == "freya" ];
    then 
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
    else
        message
        exit 1
    fi
# Debian
elif [ "$lsb" == "Debian" ];
then
	if [ $codename == "jessie" ] || [ $codename == "stretch" ] || [ $codename == "sid" ];
	then
		echo -e "\nPlatform requirements satisfied, proceeding ...\n"
	else
        message	
        exit 1
	fi
else
	message
	exit 1
fi
fi
}

sysinitdaemon_get(){

sysinitdaemon="systemd"

if [ "$lsb" == "Ubuntu" ];
then
	if [ $codename == "trusty" ];
	then
        sysinitdaemon="upstart"
	fi
# Elementary
elif [ "$lsb" == "elementary OS" ];
then
    if [ $codename == "freya" ];
    then 
        sysinitdaemon="upstart"
    fi
fi

echo $sysinitdaemon
}

install(){
echo -e "\nDownloading DisplayLink Ubuntu driver:"
wget -c http://downloads.displaylink.com/publicsoftware/DisplayLink_Ubuntu_${version}.zip
# prep
mkdir $driver_dir
echo -e "\nPrepring for install ...\n"
test -d $driver_dir && /bin/rm -Rf $driver_dir
unzip -d $driver_dir DisplayLink_Ubuntu_${version}.zip
chmod +x $driver_dir/displaylink-driver-${version}.run
./$driver_dir/displaylink-driver-${version}.run --keep --noexec
mv displaylink-driver-${version}/ $driver_dir/displaylink-driver-${version}

# Patch the kernel driver source, to be able to nuild it for kernel 4.5.0
mkdir evdi-${version}
cd evdi-${version}
tar -zxvf ../$driver_dir/displaylink-driver-${version}/evdi-${version}-src.tar.gz
patch -p0 < ../evdi-${version}-linux-4.5.0.patch
tar -zcf ../$driver_dir/displaylink-driver-${version}/evdi-${version}-src.tar.gz ./
cd ..



# get sysinitdaemon
sysinitdaemon=$(sysinitdaemon_get)

# modify displaylink-installer.sh
sed -i "s/SYSTEMINITDAEMON=unknown/SYSTEMINITDAEMON=$sysinitdaemon/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
sed -i "s/"179"/"17e9"/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
sed -i "s/detect_distro/#detect_distro/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh 
sed -i "s/#detect_distro()/detect_distro()/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh 
sed -i "s/check_requirements/#check_requirements/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh
sed -i "s/#check_requirements()/check_requirements()/g" $driver_dir/displaylink-driver-${version}/displaylink-installer.sh

# install
echo -e "\nInstalling ... \n"
cd $driver_dir/displaylink-driver-${version} && sudo ./displaylink-installer.sh install

echo -e "\nNew UDEV rules ... \n"
printf "ACTION==\"add\", SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"17e9\", ATTRS{idProduct}==\"4307\" RUN+=\"/bin/systemctl start displaylink.service\"\nACTION==\"remove\", SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"17e9\", ATTRS{idProduct}==\"4307\" RUN+=\"/bin/sh -c '/bin/systemctl stop displaylink.service; /usr/bin/xrandr --output eDP1 --auto'\"\n" | sudo tee /etc/udev/rules.d/99-displaylink.rules

sudo systemctl disable displaylink.service

sudo udevadm control --reload-rules

echo -e "\nInstall complete, please reboot to apply the changes\n"
}

# uninstall
uninstall(){

# ToDo: add confirmation before uninstalling?
echo -e "\nUninstalling ...\n"

cd $driver_dir/displaylink-driver-${version} && sudo ./displaylink-installer.sh uninstall
sudo rmmod evdi

# cleanup
# Todo: add confirmation before removing
cd -
rm -r $driver_dir
rm DisplayLink_Ubuntu_${version}.zip
rm -r evdi-${version}

echo -e "\nUninstall complete\n"
}

post(){
eval $(rm -r $driver_dir)
eval $(rm DisplayLink_Ubuntu_${version}.zip)
}

echo -e "\nDisplayLink driver for Debian GNU/Linux\n"

read -p "[I]nstall
[U]ninstall
Select a key: [i/u]: " answer

if [[ $answer == [Ii] ]];
then
	distro_check
	install
elif [[ $answer == [Uu] ]];
then
	distro_check
	uninstall
else
	echo -e "\nWrong key, aborting ...\n"
	exit 1
fi