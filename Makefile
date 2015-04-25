
#SSH_USERHOST=user@host
SSH_USERHOST?=

REQUIREMENTS_TXT=requirements.txt

help:
	@echo "brw"
	@echo "install"
	@echo "supervisord (ssv)"
	@echo "supervisorctl (sv)"
	@ech

install: \
	install_pbm \
	install_pyline \
	install_pgs \
	install_pbm \
	install_brw \
	install_requirements.txt \
	install_supervisord \
	install_supervisord.conf \

install_pbm:
	pip install -v -e git+https://github.com/westurner/pbm#egg=pbm

install_pyline:
	pip install -v -e git+https://github.com/westurner/pyline@develop#egg=pyline

install_pgs:
	pip install -v -e git+https://github.com/westurner/pgs@develop#egg=pgs

install_pbm:
	pip install tornado
	pip install -v -e git+https://github.com/westurner/pbm@master#egg=pbm

install_brw: ${_BRW}

${_BRW}:
	git clone https://github.com/westurner/brw ${_BRW}


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
VIRTUAL_ENV=${CUR_DIR}
endif

_SRC=${VIRTUAL_ENV}/src
_BRW=${_SRC}/brw

# Set
ifeq (${__IS_MAC},true)
CHROME_BIN=open --wait-apps --new -b com.google.Chrome --args
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

CHROME_PROFILE_PATH=${user-data-dir}/${profile-directory}


PROXYD_PORT=60880
PROXYD_LISTEN_HOSTNAME=localhost

MTMPRX_PORT=60881
MTMPRX_LISTEN_HOSTNAME=${PROXYD_LISTEN_HOSTNAME}

PROXY_IP=127.0.0.1
# PROXY_HOST=${PROXYD_LISTEN_HOSTNAME} # if this is an IP, EXCLUDE PROXY_HOST is unnecessary
#
PROXY_PORT=${MTMPRX_PORT}
PROXY_PORT=${PROXYD_PORT}
PROXY_SOCKS_VERSION=5

# Force Chrome to resolve DNS over SOCKS v5 (or NOT_FOUND)
host-resolver-rules?="MAP * 0.0.0.0"
ifeq (${PROXY_IP}, undefined)
PROXY_SOCKS_SERVER=${PROXY_HOST}:${PROXY_PORT}
proxy-server=socks5://${PROXY_HOST}:${PROXY_PORT}
# If DNS is required to lookup the proxy server, EXCLUDE that fqdn
host-resolver-rules+=" EXCLUDE ${PROXY_HOST}"
else
PROXY_SOCKS_SERVER=${PROXY_IP}
proxy-server=socks5://${PROXY_IP}:${PROXY_PORT}
endif

HOMEPAGE='about:blank'
ISO_DATETIME=$(shell date +'%F %T%z')
HOMEPAGE_TITLE=\#${ENV_NAME} (${ISO_DATETIME})
HOMEPAGE='$(shell echo 'data:text/html, <html style="font-family:Helvetica; background: \#333; width: 400px; margin: 0 auto; color: white;" contenteditable><title>${HOMEPAGE_TITLE}</title><p style="color: white;"><br>${HOMEPAGE_TITLE}<br>.</p>')'

CHROME_ARGS__=--proxy-server='${proxy-server}' \
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
			--no-referrers \
			${CHROME_ARGS}
	
# #disable-hyperlink-auditing=enable
# #disable-javascript-harmony-shipping
# #enable-devtools-experiments=enable
# #enable-md-settings
# #enable-site-per-process=disabled
# #enable-tab-audio-muting
# #enable-website-settings-manager=enable
# #enhanced-bookmarks-experiment=disabled
# #extension-content-verification=
# #ignore-gpu-blacklist
# #mark-non-secure-as=dubious
# #remember-cert-error-decisions=1d,3d,1w,1m,3m
# #save-page-as-mhtml=enable
# #ssl-version-min
#
# linux:
# #enable-smooth-scrolling
			
URI=about:blank
URI=
URI=chrome://history
URI=${HOMEPAGE}

_VARCACHE?=${VIRTUAL_ENV}/var/cache
_VARLOG?=${VIRTUAL_ENV}/var/log
_VARCACHE_SSH=${_VARCACHE}/ssh
_VARCACHE_MTMPRX=${_VARCACHE}/mtm
_VARCACHE_CHROME=${_VARCACHE}/chrome
_VARCACHE_BRW=${_VARCACHE}/brw

set-facls:
	(umask 0026; mkdir -p ${_VARLOG} || true)
	chmod go-rw ${_VARLOG}
	(umask 0026; mkdir -p ${_VARLOG_BRW} || true)
	chmod go-rw ${_VARLOG_BRW}
	(umask 0026; mkdir -p ${_VARCACHE} || true)
	chmod go-rw ${_VARCACHE}
	(umask 0026; mkdir -p ${_VARCACHE_SSH} || true)
	chmod go-rw ${_VARCACHE_SSH}
	(umask 0026; mkdir -p ${_VARCACHE_MTMPRX} || true)
	chmod go-rw ${_VARCACHE_MTMPRX}
	(umask 0026; mkdir -p ${_VARCACHE_CHROME} || true)
	chmod go-rw ${_VARCACHE_CHROME}
	(umask 0026; mkdir -p ${_VARCACHE_BRW} || true)
	chmod go-rw ${_VARCACHE_BRW}
	(umask 0026; mkdir -p ${user-data-dir} || true)
	chmod go-rw ${user-data-dir}

## SSH 

SSH_PID_FILE=${_VARCACHE_SSH}/.pid
open-ssh:
	test -n "$(SSH_USERHOST)" || (echo "SSH_USERHOST=$(SSH_USERHOST)" && exit 1)
	-$(MAKE) set-facls
	date +'%F %T%z'
	cd . && { set -m; \
	  ssh -v -N -D${PROXYD_PORT} ${SSH_USERHOST} & \
	  echo "$$!" > ${SSH_PID_FILE} ; \
	  cat ${SSH_PID_FILE}; \
	  fg; }

# $(SSH_PID_FILE): open-ssh

close-ssh:
	test -f ${SSH_PID_FILE}
	(umask 0026; mkdir -p ${_VARCACHE_SSH})
	kill -9 $(shell cat "${SSH_PID_FILE}") || true
	rm ${SSH_PID_FILE}
	-$(MAKE) set-facls


MTMPRX_PID_FILE=${_VARCACHE_MTMPRX}/.pid
open-mtm:
	$(MAKE) close-mtm || true
	@$(MAKE) set-facls
	date +'%F %T%z'
	cd . && { set -m; \
		mitmdump --socks -a \
			-p ${MTMPRX_PORT} \
			-b "${MTMPRX_LISTEN_HOSTNAME}" \
			-s "./scripts/mtmprx/doheaders.py"  & \
		echo "$$!" > ${MTMPRX_PID_FILE} ; \
		cat ${MTMPRX_PID_FILE}; \
		fg; }

close-mtm:
	test -f ${MTMPRX_PID_FILE}
	kill -9 $(shell cat "${MTMPRX_PID_FILE}") || true
	rm ${MTMPRX_PID_FILE}
	@$(MAKE) set-facls

## Chrome Browser

CHROME_PID_FILE=${_VARCACHE_CHROME}/.pid
URI=${HOMEPAGE}
open-chrome:
	@$(MAKE) set-facls
	date +'%F %T%z'
	echo "CHROME_PROFILE_PATH='${CHROME_PROFILE_PATH}'"
	cd . && { set -m; \
		${CHROME_BIN} ${CHROME_ARGS__} ${URI} & \
		echo "$$!" > ${CHROME_PID_FILE} ; \
		cat ${CHROME_PID_FILE}; \
		fg; }

close-chrome:
	test -f ${CHROME_PID_FILE}
	kill -9 $(shell cat "${CHROME_PID_FILE}")
	rm ${CHROME_PID_FILE}
	@$(MAKE) set-facls

_VARLOG_BRW=${_VARLOG}/brw
BRW_PID_FILE=${_VARCACHE_BRW}/.pid


BRW_HOST=localhost
BRW_PORT=60883

serve-brw-pgs:
	# make install_brw install_pgs
	# (cd ${_BRW}; pgs -v -g . -r <gittagbranchcommit>;)
	@$(MAKE) set-facls
	(cd ${_BRW}; \
		pgs -v -p . -H ${BRW_HOST} -P ${BRW_PORT} \
		| tee ${_VARLOG_BRW}/pgs.log)

close-brw-pgs:
	test -f ${BRW_PID_FILE}
	kill -9 $(shell cat "${BRW_PID_FILE}")
	rm ${BRW_PID_FILE}
	@$(MAKE) set-facls


serve-brw:
	$(MAKE) serve-brw-pgs &
	$(MAKE) open-chrome URI=http://${BRW_HOST}:${BRW_PORT}

PBM_HOST=localhost
PBM_PORT=60884
serve-pbmweb:
	pbmweb -H ${PBM_HOST} -P ${PBM_PORT} -f "${CHROME_PROFILE_PATH}/Bookmarks"

organize-bookmarks:
	# Note: Chrome writes ./Bookmarks
	# * at shutdown
	# * before 'Export as HTML'
	# So, the browser must be closed for these changes to not be overwritten.
	#
	# $ make close-chrome
	pbm --skip-prompt --organize '${CHROME_PROFILE_PATH}/Bookmarks'

list-bookmarks:
	pbm --print-all '${CHROME_PROFILE_PATH}/Bookmarks'

list-bookmarks-by-date-oldest-first:
	pbm --print-all --by-date '${CHROME_PROFILE_PATH}/Bookmarks'

list-bookmarks-by-date-newest-first:
	pbm --print-all --by-date -r '${CHROME_PROFILE_PATH}/Bookmarks'

list-bookmark-words:
	@pbm --print-all --by-date -r '${CHROME_PROFILE_PATH}/Bookmarks' \
		| grep '^# name :' \
		| pyline --input-delim-split-max=3 -F ' ' 'w[3:]' \
		| pyline 'l.replace(" ", "\n").replace("#","\n").replace("# ","\n")' \
		| pyline '"".join(c for c in l if c not in (dict.fromkeys("\n ,:;(){}<>'"'"'\"|!-"))).lower()' \
		| grep -v '^http'

TAG_BASE_URI=\#
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


### supervisord

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

### 

open:
	#$(MAKE) install_supervisord supervisord supervisorctl SUPERVISOR_CMD=status
	$(MAKE) supervisord
	$(MAKE) supervisorctl SUPERVISOR_CMD="status"
	$(MAKE) open-chrome

close:
	$(MAKE) supervisorctl SUPERVISOR_CMD="shutdown"
	$(MAKE) close-ssh
	$(MAKE) supervisorctl SUPERVISOR_CMD="status" || true
