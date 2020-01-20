#!/bin/bash

SUCCESS=0
ERROR=1

let exit_code=${SUCCESS}

this_uid=$(id -un 2> /dev/null)
static_ip_script="/usr/local/sbin/networking.sh"
rc_local_file="/etc/rc.local"

if [ "${this_uid}" = "root" ]; then
    echo "Adding static ip networking to '${rc_local_file}'"
    this_guid=$(id -gn 2> /dev/null)

    if [ ! -z "${this_guid}" ]; then
        this_guid=":${this_guid}"
    fi

    # Make sure ${rc_local_file} is present
    if [ ! -e "${rc_local_file}" ]; then
        echo "  Creating '${rc_local_file}'"
        echo "#!/bin/bash" > "${rc_local_file}"
        echo "exit 0"     >> "${rc_local_file}"
    fi

    # Check for script presence in ${rc_local_file}
    let rc_local_exists=$(egrep -c "${static_ip_script}" /etc/rc.local 2> /dev/null)

    if [ ${rc_local_exists} -eq 0 -a -x "${static_ip_script}" ]; then
        exit_line=$(egrep -n "^exit.*$" "${rc_local_file}" | tail -1)

        if [ -z "${exit_line}" ]; then
            exit_line="exit 0"
        else
            exit_line_number=$(echo "${exit_line}" | awk -F':' '{print $1}')
        fi

        echo "  Seeding '${rc_local_file}' with '${static_ip_script}'"

        # Flush the last exit line from the file, if defined
        if [ ! -z "${exit_line_number}" ]; then
            sed -i -e "${exit_line_number}d" "${rc_local_file}"
            exit_line=$(echo "${exit_line}" | sed -e 's|^[0-9]*:||g')
        fi

        cat >> "${rc_local_file}" <<EORCL

# Start up static networking (if possible)
if [ -x "${static_ip_script}" ]; then
    ${static_ip_script}
fi

EORCL

        echo "${exit_line}" >> "${rc_local_file}"
        chown ${this_uid}${this_guid} "${rc_local_file}"
        chmod 750 "${rc_local_file}"
    else
        echo "  Entry '${static_ip_script}' in '${rc_local_file}' already exists"
    fi

else
    echo "  This script must be run by root.  Try again with sudo"
    let exit_code=${ERROR}
fi

if [ ${exit_code} -eq ${SUCCESS} ]; then
    echo "SUCCESS"
fi

exit ${exit_code}
