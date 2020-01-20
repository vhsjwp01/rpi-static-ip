# RPi Static IP
A simple shell script meant for injection into /etc/rc.local to setup a static IP address on a raspberry pi

### Prerequisites
* A working systemd based Linux distro

### Installation
```
prompt$> make install
```

Installs as `/usr/local/sbin/networking.sh`

### Usage
* The most effective way to leverage this script is by adding it to `/etc/rc.local`
  * You can inject it into your existing `/etc/rc.local` by running the following command from within this repo
```
prompt$> make rc_local
```
