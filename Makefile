
#SSH_USERHOST=user@host
SSH_USERHOST?=


REQUIREMENTS_TXT=requirements.txt

install: \
	install_promiumbookmarks \
	install_pyline \
	install_supervisord \
	install_supervisord.conf \
	install_requirements.txt

install_promiumbookmarks:
	pip install -v -e git+https://github.com/westurner/promiumbookmarks#egg=promiumbookmarks

install_pyline:
	pip install -v -e git+https://github.com/westurner/pyline@develop#egg=pyline

install_supervisord:
	pip install -v supervisor

install_requirements.txt:
	(test -f '${REQUIREMENTS_TXT}' && \
	pip install -v -r '${REQUIREMENTS_TXT}')


# ENV_NAME=${_APP:-${VIRTUAL_ENV:-${CUR_DIR}}}
ifeq (${_APP}, undefined)
	ifeq (${VIRTUAL_ENV}, undefined)
		ENV_NAME=${CUR_DIR}
	else
		ENV_NAME=$(shell dirname '${CUR_DIR}')
	endif
else
	ENV_NAME=${_APP}
endif


ifeq (${VIRTUAL_ENV}, undefined)
	VIRTUAL_ENV?=${CUR_DIR}
endif


# Set
ifeq (${__IS_MAC},true)
CHROME_BIN=open --new -b com.google.Chrome
SEDOPTS=-i'' -e
user-data-dir=${HOME}/Library/Application Support/Google/Chrome
else
CHROME_BIN=/usr/bin/google-chrome
SEDOPTS=-i
user-data-dir=${HOME}/.config/google/chrome
endif

ifeq (${VIRTUAL_ENV}, undefined)
else
user-data-dir=${_HOME}/${_APP}/.config/google/chrome
endif

profile-directory?=Profile 1

CHROME_PROFILE_DIR=${user-data-dir}/${profile-directory}

PROXY_IP=127.0.0.1
PROXY_HOST=localhost  # if this is an IP, EXCLUDE PROXY_HOST is unnecessary
PROXY_PORT=60880

SOCKS_VERSION=5
all-proxy=true

# Force Chrome to resolve DNS over SOCKS v5 (or NOT_FOUND)
host-resolver-rules?="MAP * 0.0.0.0"
ifeq (${PROXY_IP}, undefined)
	SOCKS_SERVER=${PROXY_HOST}:${PROXY_PORT}
	proxy-server=socks5://${PROXY_HOST}:${PROXY_PORT}
	# If DNS is required to lookup the proxy server, EXCLUDE that fqdn
	host-resolver-rules+="EXCLUDE ${PROXY_HOST}"
else
	SOCKS_SERVER=${PROXY_IP}
	proxy-server=socks5://${PROXY_IP}:${PROXY_PORT}
endif

HOMEPAGE='about:blank'
ISO_DATETIME=$(shell date +'%F %T%z')
HOMEPAGE_TITLE=\#${ENV_NAME} (${ISO_DATETIME})
HOMEPAGE='$(shell echo 'data:text/html, <html style="font-family:Helvetica; background: \#333; width: 400px; margin: 0 auto; color: white;" contenteditable><title>${HOMEPAGE_TITLE}</title><p style="color: white;"><br>${HOMEPAGE_TITLE}<br>.</p>')'

CHROME_ARGS=--proxy-server='${proxy-server}' \
			--host-resolver-rules=${host-resolver-rules} \
			--dns-prefetch-disable \
			--learning \
			--profile-directory="${profile-directory}" \
			--no-default-browser-check \
			--disable-java \
			--disable-icon-ntp \
			--no-pings \
			--homepage="about:blank" \
 			--user-data-dir=${user-data-dir} \
			--no-referrers
	
			
URI=about:blank
URI=
URI=chrome://history
URI=${HOMEPAGE}

#_VARCACHE=${VIRTUAL_ENV}/var/cache
_VARCACHE_SSH=${_VARCACHE}/ssh
_VARCACHE_CHROME=${_VARCACHE}/chrome


set-facls:
	(umask 0026; mkdir -p ${_VARCACHE} || true)
	chmod go-rw ${_VARCACHE}
	(umask 0026; mkdir -p ${_VARCACHE_SSH} || true)
	chmod go-rw ${_VARCACHE_SSH}
	(umask 0026; mkdir -p ${_VARCACHE_CHROME} || true)
	chmod go-rw ${_VARCACHE_CHROME}
	(umask 0026; mkdir -p ${user-data-dir} || true)
	chmod go-rw ${user-data-dir}

## SSH 

SSH_PID_FILE=${_VARCACHE_SSH}/.pid
open-ssh-socks:
	test -n "$(SSH_USERHOST)" || (echo "SSH_USERHOST=$(SSH_USERHOST)" && exit 1)
	(umask 0026; mkdir -p ${_VARCACHE_SSH})
	-$(MAKE) set-facls
	date +'%F %T%z'
	cd . && { set -m; \
		ssh -N -D${PROXY_PORT} ${SSH_USERHOST} & \
		echo "$$!" > ${SSH_PID_FILE} ; \
		cat ${SSH_PID_FILE}; \
		fg; }

# $(SSH_PID_FILE): open-ssh-socks

close-ssh-socks:
	test -f ${SSH_PID_FILE}
	kill -9 $(shell cat "${SSH_PID_FILE}") || true
	rm ${SSH_PID_FILE}


## Chrome Browser

CHROME_PID_FILE=${_VARCACHE_CHROME}/.pid
URI?=${HOMEPAGE}
open-chrome:
	-$(MAKE) set-facls
	date +'%F %T%z'
	echo "CHROME_PROFILE_DIR='${CHROME_PROFILE_DIR}'"
	cd . && { set -m; \
		${CHROME_BIN} --args ${CHROME_ARGS} ${URI} & \
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

list-bookmarks:
	promiumbookmarks --print-all '${CHROME_PROFILE_DIR}/Bookmarks'

list-bookmarks-by-date-oldest-first:
	promiumbookmarks --print-all --by-date '${CHROME_PROFILE_DIR}/Bookmarks'

list-bookmarks-by-date-newest-first:
	promiumbookmarks --print-all --by-date -r '${CHROME_PROFILE_DIR}/Bookmarks'

list-bookmark-words:
	@promiumbookmarks --print-all --by-date -r '${CHROME_PROFILE_DIR}/Bookmarks' \
		| grep '^# name :' \
		| pyline --input-delim-split-max=3 -F ' ' 'w[3:]' \
		| pyline 'l.replace(" ", "\n").replace("#","\n").replace("# ","\n")' \
		| pyline '"".join(c for c in l if c not in (dict.fromkeys("\n ,:;(){}<>'"'"'\"|!-"))).lower()' \
		| grep -v '^http'

TAG_BASE_URI?=\#
list-bookmark-words-template:
	@echo '<html>'
	@echo '<head>'
	@echo '<style>'
	@echo 'a { text-decoration: none; }'
	@echo 'p.tagcloud { text-align: center; }'
	@echo 'a.tagname { padding: 4px; display: inline }'
	@echo 'span.count { padding-left: 2px; padding-right: 6px; opacity: 0.4; }'
	@echo 'a.tagn_0 { font-size: 1.2em; }'
	@echo 'a.tagn_1 { font-size: 1.4em; }'
	@echo 'a.tagn_2 { font-size: 1.6em; }'
	@echo 'a.tagn_3 { font-size: 1.8em; }'
	@echo 'a.tagn_4 { font-size: 2.0em; }'
	@echo 'a.tagn_5 { font-size: 2.2em; }'
	@echo 'a.tagn_6 { font-size: 2.4em; }'
	@echo 'a.tagn_7 { font-size: 2.6em; }'
	@echo 'a.tagn_8 { font-size: 2.8em; }'
	@echo 'a.tagn_9 { font-size: 3.0em; }'
	@echo 'a.tagn_10 { font-size: 3.2em; }'
	@echo '</style>'
	@echo '</head>'
	@echo '<body>'
	@echo '<div class="body">'
	@echo '<p class="tagcloud">'
	$(MAKE) --quiet list-bookmark-words-uniq-with-count \
		| pyline -m cgi \
		'u"""<a id="{1}" class="tagname tagn_{2}" target="_blank" href="${TAG_BASE_URI}{1}/"><span class="keyword">{1}</span></a><span class="count">{0}</span>""".format(int(w[0]), cgi.escape(w[1]), int(min((((int(w[0]) / 20.0) * 10.0), 10,))))'
	@echo '</p>'
	@echo '</body>'
	@echo '</html>'

list-bookmark-words-tagcloud:
	$(MAKE) list-bookmark-words-template > tags.html
	$(MAKE) open-chrome URI=file://$${PWD}/tags.html

list-bookmark-words-uniq:
	@$(MAKE) list-bookmark-words | sort -u

list-bookmark-words-uniq-with-count:
	@$(MAKE) list-bookmark-words | sort | uniq -c

list-bookmark-words-uniq-by-count-descending:
	@$(MAKE) list-bookmark-words | sort | uniq -c | sort -n -r

_ETC=${VIRTUAL_ENV}/etc
_SVCFG=${_ETC}/supervisord.conf

install_supervisord.conf:
	ln -s $(shell pwd)/supervisord.conf ${_SVCFG}

supervisord:
	supervisord -c ${_SVCFG}

ssv: supervisord

supervisorctl:
	supervisorctl -c ${_SVCFG} ${SUPERVISOR_CMD}

sv: supervisorctl

open: install_supervisord supervisord
	$(MAKE) supervisorctl SUPERVISOR_CMD="status"
	$(MAKE) open-chrome

close:
	$(MAKE) supervisorctl SUPERVISOR_CMD="shutdown"
	$(MAKE) close-ssh-socks
	$(MAKE) supervisorctl SUPERVISOR_CMD="status" || true
