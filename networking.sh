#!/bin/bash
#set -x

PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"
TERM="vt100"
export TERM PATH

SUCCESS=0
ERROR=1

err_msg=""
exit_code=${SUCCESS}

defaults_file="/etc/default/static_ip"

### Put the following information in '${defaults_file}'
# eth_dev="<eth device - MANDATORY>"
# eth_dev_ip="<desired static ip - MANDATORY>"
# eth_dev_netmask="<desired netmask - MANDATORY>"
# eth_dev_gateway="<desired gateway ip - MANDATORY>"
# dns_server_ip="<desired DNS server ip - MANDATORY>"
# dns_search_domain="<DNS search domain - OPTIONAL>"
# systemctl_services="<space separated list of systemctl services to be restarted>"

if [ -s "${defaults_file}" ]; then
    source "${defaults_file}"
fi

if [ -z "${eth_dev}" -o -z "${eth_dev_ip}" -o -z "${eth_dev_netmask}" -o -z "${eth_dev_gateway}" -o -z "${dns_server_ip}" ]; then
    err_msg="Not enought arguments defined to set up a static IP address on this node"
    let exit_code=${ERROR}
fi

# WHAT: Setup command vars
# WHY:  Needed later
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    my_ifconfig=$(which ifconfig 2> /dev/null)
    my_logger=$(which logger 2> /dev/null)
    my_resolvconf=$(which resolvconf 2> /dev/null)
    my_route=$(which route 2> /dev/null)
    my_systemctl=$(which systemctl 2> /dev/null)

    if [ "${my_ifconfig}" = "" ]; then
        echo "    Could not locate the ifconfig command" >&2
        err_msg="Mandatory command not found"
        let exit_code=${ERROR}
    fi

    if [ "${my_logger}" = "" ]; then
        echo "    Could not locate the logger command" >&2
        err_msg="Mandatory command not found"
        let exit_code=${ERROR}
    fi

    if [ "${my_resolvconf}" = "" ]; then
        echo "    Could not locate the resolvconf command" >&2
        err_msg="Mandatory command not found"
        let exit_code=${ERROR}
    fi

    if [ "${my_route}" = "" ]; then
        echo "    Could not locate the route command" >&2
        err_msg="Mandatory command not found"
        let exit_code=${ERROR}
    fi

    if [ "${my_systemctl}" = "" ]; then
        echo "    Could not locate the systemctl command" >&2
        err_msg="Mandatory command not found"
        let exit_code=${ERROR}
    fi

fi

# WHAT: Must be root to run this script
# WHY:  Won't work otherwise
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    my_user_id=$(id -un)

    if [ "${my_user_id}" != "root" ]; then
        err_msg="Must be root to run this script"
        let exit_code=${ERROR}
    fi

fi

# WHAT: Shut down any DHCP processes
# WHY:  We don't want to use them
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    enabled_dhcp_services=$(systemctl list-unit-files | egrep -i "^dhcp" | awk '/enabled/ {print $1}')

    for enabled_dhcp_service in ${enabled_dhcp_services} ; do
        ${my_systemctl} stop ${enabled_dhcp_service} > /dev/null 2>&1
        let exit_code+=${?}
        ${my_systemctl} disable ${enabled_dhcp_service} > /dev/null 2>&1
        let exit_code+=${?}
    done

    if [ ${exit_code} -ne ${SUCCESS} ]; then
        err_msg="Errors were encountered disabling dhcpd services via systemctl"
    fi

fi

# WHAT: Workaround for broken DHCPCD static IP address assignment on RPi
# WHY:  Could not get dhcpcd config settings to work, so gave up on that
#       in favor of the old standby from long ago
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    ${my_ifconfig} ${eth_dev} ${eth_dev_ip} netmask ${eth_dev_netmask} &&
    ${my_route} add default gw ${eth_dev_gateway}

    for systemd_service in ${systemctl_services} ; do
        ${my_systemctl} restart ${systemd_service}

        if [ ${?} -ne ${SUCCESS} ]; then
            err_msg="Service ${systemd_service} failed to start"
            let exit_code=${ERROR}
            break
        fi

    done

    # Seed resolv.conf using the 'resolvconf' command
    if [ ${exit_code} -eq ${SUCCESS} ]; then
        resolv_dns_search_domain=""

        # Add in our dns search domain if it is defined
        if [ ! -z "${dns_search_domain}" ]; then
            resolv_dns_search_domain="search ${dns_search_domain}\n"
        fi

        echo -ne "${resolv_dns_search_domain}nameserver ${dns_server_ip}\n" | ${my_resolvconf} -a ${eth_dev}
    fi

fi

# WHAT: Complain if necessary to syslog then exit
# WHY:  Success or failure, either way we are through!
#
if [ ${exit_code} -ne ${SUCCESS} ]; then

    if [ "${err_msg}" != "" ]; then
        echo "    ERROR:  ${err_msg} ... processing halted" | logger -t "static_ip_assignment"
    fi

fi

exit ${exit_code}
