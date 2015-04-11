
#CHROME_PROFILE_DIR

SSH_CONN?=

# REQUIREMENTS_TXT=${CUR_DIR}/requirements.txt
REQUIREMENTS_TXT=requirements.txt

install: \
	install_promiumbookmarks \
	install_supervisord \
	install_supervisord.conf \
	install_requirements.txt

install_promiumbookmarks:
	pip install -v -e git+https://github.com/westurner/promiumbookmarks#egg=promiumbookmarks

install_supervisord:
	pip install -v supervisor

install_requirements.txt:
	(test -f '${REQUIREMENTS_TXT}' && \
	pip install -v -r '${REQUIREMENTS_TXT}')


# env_name=${_APP:-${VIRTUAL_ENV:-${CUR_DIR}}}
ifeq (${_APP}, undefined)
	ifeq (${VIRTUAL_ENV}, undefined)
		env_name=${CUR_DIR}
	else
		env_name=$(shell dirname '${CUR_DIR}')
	endif
else
	env_name=${_APP}
endif


ifeq (${VIRTUAL_ENV}, undefined)
	VIRTUAL_ENV?=${CUR_DIR}
endif


# Set
ifeq (${__IS_MAC},true)
CHROME_BIN=open -n -b com.google.Chrome --args
SEDOPTS=-i '' -e
else
CHROME_BIN=/usr/bin/google-chrome
SEDOPTS=-i
endif

PROXY_IP=127.0.0.1
PROXY_HOST=localhost  # if this is an IP, EXCLUDE PROXY_HOST is unnecessary
PROXY_PORT=60880

SOCKS_VERSION=5
all-proxy=true

# Force Chrome to resolve DNS over SOCKS v5 (or NOT_FOUND)
host-resolver-rules?="MAP * 0.0.0.0"
ifeq (${PROXY_IP}, undefined)
	SOCKS_SERVER=${PROXY_HOST}:${PROXY_PORT}
	PROXY_URI=socks5://${PROXY_HOST}:${PROXY_PORT}
	# If DNS is required to lookup the proxy server, EXCLUDE that fqdn
	host-resolver-rules+="EXCLUDE ${PROXY_HOST}"
else
	SOCKS_SERVER=${PROXY_IP}
	PROXY_URI=socks5://${PROXY_IP}:${PROXY_PORT}
endif

#SSH_CONN="other@proxy"
PROFILE_DIRNAME=Profile 3
CHROME_PROFILE_DIR=/Users/W/Library/Application Support/Google/Chrome/${PROFILE_DIRNAME}

HOMEPAGE='about:blank'
ISO_DATETIME=$(shell date +'%F %T%z')
HOMEPAGE_TITLE=\#${env_name} (${ISO_DATETIME})
HOMEPAGE=$(shell echo 'data:text/html, <html style="font-family:Helvetica; background: \#333; width: 400px; margin: 0 auto; color: white;" contenteditable><title>${HOMEPAGE_TITLE}</title><p style="color: white;"><br>${HOMEPAGE_TITLE}<br>.</p>')

CHROME_ARGS=--proxy-server='${PROXY_URI}' \
			--host-resolver-rules=${host-resolver-rules} \
			--dns-prefetch-disable \
			--learning \
			--profile-directory="${PROFILE_DIRNAME}" \
			--no-default-browser-check \
			${HOMEPAGE}
			
URI=about:blank
URI=
URI=chrome://history

#_VARCACHE=${VIRTUAL_ENV}/var/cache
_VARCACHE_SSH=${_VARCACHE}/ssh
_VARCACHE_CHROME=${_VARCACHE}/chrome


set-facls:
	chmod go-rw ${_VARCACHE}
	chmod go-rw ${_VARCACHE_SSH}
	chmod go-rw ${_VARCACHE_CHROME}

## SSH 

SSH_PID_FILE=${_VARCACHE_SSH}/.pid
open-ssh-socks:
	(umask 0026; mkdir -p ${_VARCACHE_SSH})
	$(MAKE) set-facls
	date +'%F %T%z'
	cd . && { set -m; \
		ssh -N -v -D${PROXY_PORT} ${SSH_CONN} & \
		echo "$$!" > ${SSH_PID_FILE} ; \
		cat ${SSH_PID_FILE}; \
		fg; }

# $(SSH_PID_FILE): open-ssh-socks

close-ssh-socks:
	test ${SSH_PID_FILE}
	kill -9 $(shell cat "${SSH_PID_FILE}")
	rm ${SSH_PID_FILE}


## Chrome Browser

CHROME_PID_FILE=${_VARCACHE_CHROME}/.pid
open-chrome:
	(umask 0026; mkdir -p ${_VARCACHE_CHROME}
	$(MAKE) set-facls
	date +'%F %T%z'
	cd . && { set -m; \
		${CHROME_BIN} ${CHROME_ARGS} "${URI}" & \
		echo "$$!" > ${CHROME_PID_FILE} ; \
		cat ${CHROME_PID_FILE}; \
		fg; }

close-chrome:
	test ${CHROME_PID_FILE}
	kill -9 $(shell cat "${CHROME_PID_FILE}")
	rm ${CHROME_PID_FILE}



rebuild-bookmarks:
	# ${MAKE} close-chrome; sleep 3
	promiumbookmarks --skip-prompt --overwrite '${CHROME_PROFILE_DIR}/Bookmarks'


_ETC=${VIRTUAL_ENV}/etc
_SVCFG=${_ETC}/supervisord.conf

install_supervisord.conf:
	ln -s $(shell pwd)/supervisord.conf ${_SVCFG}

supervisord:
	supervisord -c ${_SVCFG}

supervisorctl:
	supervisorctl -c ${_SVCFG}

