# RPi Static IP
A simple shell script meant for injection into `/etc/rc.local` to setup a static IP address on a raspberry pi

### Prerequisites
* A working systemd based Linux distro

### Installation
```
prompt$> make install
```

Installs as `/usr/local/sbin/networking.sh`

### Usage
* The script expects to find a defaults file called `/etc/default/static_ip` whose contents consist of the following:

```
eth_dev="<eth device - MANDATORY>"
eth_dev_ip="<desired static ip - MANDATORY>"
eth_dev_netmask="<desired netmask - MANDATORY>"
eth_dev_gateway="<desired gateway ip - MANDATORY>"
dns_server_ip="<desired DNS server ip - MANDATORY>"
dns_search_domain="<DNS search domain - OPTIONAL>"
systemctl_services="<space separated list of systemctl services to be restarted>"
```

* The most effective way to leverage this script is by adding it to `/etc/rc.local`
  * You can inject it into your existing `/etc/rc.local` by running the following command from within this repo
```
prompt$> make rc_local
```
