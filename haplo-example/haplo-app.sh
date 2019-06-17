#!/bin/bash
# Haplo Platform                                    https://haplo.org
# (c) Haplo Services Ltd 2006 - 2018            https://www.haplo.com
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
# This script initializes a haplo application
#
# The assumption here is that we're running under Docker and the
# Dockerfile has passed the variables to us
#
# To avoid the values being placed in the environment in the clear
# we read them from a startup file app.values
#

if [ ! -d /home/hbuild ]; then
    exit 2
fi
cd /home/hbuild
if [ ! -f app.values ]; then
    echo "Missing startup file app.values"
    exit 2
fi
# just read it
. app.values

#
# default application template and ID
#
APPTEMPLATE="sme"
APPID="4000"

#
# check the variables are set
#
if [ -z "$APPURL" ]; then
    echo "APPURL unset"
    exit 1
fi
if [ -z "$APPNAME" ]; then
    echo "APPNAME unset"
    exit 1
fi
if [ -z "$APPUNAME" ]; then
    echo "APPUNAME unset"
    exit 1
fi
if [ -z "$APPUMAIL" ]; then
    echo "APPUMAIL unset"
    exit 1
fi
if [ -z "$APPUPASS" ]; then
    echo "APPUPASS unset"
    exit 1
fi

#
# If we have a set of plugins specified then load those
# use the minimal template in that case
# The plugins will be in subdirectories of /opt/haplo/sample-plugins
# and we copy the named subdirectory to /haplo/plugins
#
if [ -n "$APPPLUGIN" ]; then
    APPTEMPLATE="minimal"
    if [ -d /opt/haplo/sample-plugins/${APPPLUGIN} ]; then
	sudo mkdir -p /haplo/plugins
	sudo cp -r /opt/haplo/sample-plugins/${APPPLUGIN} /haplo/plugins
	sudo chown -hR haplo:haplo /haplo/plugins
    else
	echo "Invalid plugin set $APPPLUGIN"
	exit 1
    fi
fi

#
# create certs
#
if [ ! -f /haplo/sslcerts/server.crt ]; then
    echo " *** Haplo creating server certificate ***"
    cd /opt/haplo
    ./deploy/make_cert $APPURL > /dev/null
    chmod a+r /tmp/haplo-sslcerts/*
    sudo su haplo -c 'cd /tmp/haplo-sslcerts ; cp server.crt  server.crt.csr  server.key /haplo/sslcerts'
    rm -fr /tmp/haplo-sslcerts
    echo " *** Haplo server certificate created and installed ***"
fi

#
# exit if it didn't work
#
[ -f /haplo/sslcerts/server.crt ] || exit 1

#
# manually hack around blocking on /dev/random
#
if [ ! -f /opt/haplo/config/j.config ]; then
  cat > /tmp/randfix.sh <<EOF
#!/bin/sh
mv /opt/haplo/config/java.config /opt/haplo/config/j.config
echo "-Djava.security.egd=file:///dev/urandom" > /opt/haplo/config/java.config
cat /opt/haplo/config/j.config >> /opt/haplo/config/java.config
EOF
  chmod a+x /tmp/randfix.sh
  sudo su haplo -c /tmp/randfix.sh
  rm /tmp/randfix.sh
fi

#
# the app, and postgres, must be running
#
sudo /etc/init.d/postgresql start
echo " *** Waiting 5s for database to start ***"
sleep 5
sudo su haplo -c "/opt/haplo/deploy/haplo.rc do_start"
echo " *** Waiting 30s for haplo server to start ***"
sleep 30

#
# initialize the app
# if plugins specified, install those too
#
if [ ! -d /haplo/files/${APPID}/ ]; then
    rm -f /tmp/haplo-appinit.sh
    cat > /tmp/haplo-appinit.sh <<EOF
#!/bin/sh
cd /opt/haplo
db/init_app.sh haplo $APPURL "${APPNAME}" ${APPTEMPLATE} ${APPID}
sleep 1
db/create_app_user.sh $APPURL "${APPUNAME}" ${APPUMAIL} ${APPUPASS}
EOF
    if [ -n "$APPPLUGIN" ]; then
	cat >> /tmp/haplo-appinit.sh <<EOF
sleep 1
echo " *** Installing $APPPLUGIN plugins ***"
script/runner "KApp.in_application(${APPID}) {KPlugin.install_plugin('${APPPLUGIN}')}"
echo " *** Installed $APPPLUGIN plugins ***"
EOF
    fi
    chmod a+x /tmp/haplo-appinit.sh
    sudo su haplo -c "/tmp/haplo-appinit.sh"
    rm -f /tmp/haplo-appinit.sh
    echo " *** Haplo application for $APPURL initialized ***"
    echo ""
    echo "Browse to"
    echo "  http://$APPURL/"
    echo "And log in as the user you created above."
    echo ""
    echo "   *** Welcome to Haplo ***"
    echo ""
fi
