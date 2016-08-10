#!/bin/bash
# Haplo Platform                                     http://haplo.org
# (c) Haplo Services Ltd 2006 - 2016    http://www.haplo-services.com
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
# create certs
#
if [ ! -f /haplo/sslcerts/server.crt ]; then
    echo " *** Haplo creating server certificate ***"
    cd /opt/haplo
    ./deploy/make_cert $APPURL > /dev/null
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
sleep 5
sudo su haplo -c "/opt/haplo/deploy/haplo.rc do_start"
sleep 30

#
# initialize the app
#
if [ ! -d /haplo/files/4000/ ]; then
    rm -f /tmp/haplo-appinit.sh
    cat > /tmp/haplo-appinit.sh <<EOF
#!/bin/sh
cd /opt/haplo
db/init_app.sh haplo $APPURL "${APPNAME}" sme 4000
sleep 1
db/create_app_user.sh $APPURL "${APPUNAME}" ${APPUMAIL} ${APPUPASS}
EOF
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
