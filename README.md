# displaylink-debian
DisplayLink driver installer for Debian GNU/Linux and Ubuntu.

#### Problem
[DisplayLink](http://www.displaylink.com/) releases its drivers only for Ubuntu 14.04, and latest kernel version they support is 3.19. 


#### displaylink-debian

* Allows you to seamlessly install and uninstall DisplayLink drivers on Debian GNU/Linux and Ubuntu. (only 4.5 kernel)


How? Just run the script! (as regular user)

`./displaylink-debian.sh`

#### Technical

##### displaylink-debian.sh

* Downloads and extracts contents of original [DisplayLink Ubuntu driver] (http://www.displaylink.com/downloads/ubuntu.php>)

* _displaylink-debian.sh_ will modify contents of original _displaylink-installer.sh_ and patch the evdi drivers for the 4.5 kernel. After which install/uninstall is performed. 

* Supported platforms are: 
  * Debian: Jessie/Stretch/Sid (regardless of which kernel version you're using.)
  * Ubuntu >= 15.04 <= 16.04 (regardless of which kernel version you're using.)
  * Ubuntu >= 14.04 and Elementary OS (kernel >= 3.16 and Xorg >= 1.16.)

#### References

*https://github.com/AdnanHodzic/displaylink-debian
*https://github.com/sinfomicien/displaylink-evdi-opensuse
