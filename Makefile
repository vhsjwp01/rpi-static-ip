SOURCE		= networking.sh
TARGET_DIR	= /usr/local/sbin
PLATFORM	= $(shell uname -s)

install:
	if [ ! -d "${TARGET_DIR}" ]; then                              \
	    mkdir -p "${TARGET_DIR}"                                 ; \
	fi                                                           ; \
	case "${PLATFORM}" in                                          \
	    Linux)                                                     \
	        cp "${SOURCE}" "${TARGET_DIR}/${SOURCE}"            && \
	        chmod 750 "${TARGET_DIR}/${SOURCE}"                 && \
	        echo "SUCCESS"                                         \
	    ;;                                                         \
	    *)                                                         \
	        echo "Unknown (and unsupported) platform: ${PLATFORM}" \
	    ;;                                                         \
	esac

rc_local:
	./rc-local_helper.sh
