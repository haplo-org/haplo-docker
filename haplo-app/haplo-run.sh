#!/bin/bash
# Haplo Platform                                    https://haplo.org
# (c) Haplo Services Ltd 2006 - 2018            https://www.haplo.com
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
# start up a configured haplo instance
# if no configured instance found, attempt to create one
#

#
# the container has 3 logical components:
#  - the underlying OS, packages, and users
#  - the haplo stack installed in /opt/haplo
#  - data in /haplo
# the first two are always part of the image, but the data in /haplo
# might (in production, will) be a separate volume that we may need
# to initialize
#

#
# flags to track if we've already started components
#
DBSTARTED=""
APPSTARTED=""

#
# create any parts of the hierarchy that are missing
# this duplicates haplo-install.sh
#
if [ ! -d /haplo ]; then
    sudo mkdir /haplo
fi
# if an empty volume it will exist but have the wrong owner, so always chown
sudo chown haplo:haplo /haplo
for subdir in log tmp generated-downloads files textweighting plugins messages messages/app_create messages/app_modify messages/spool sslcerts
do
    if [ ! -d /haplo/$subdir ]; then
	sudo mkdir /haplo/$subdir
	sudo chown haplo:haplo /haplo/$subdir
    fi
done
if [ ! -d /haplo/textidx ]; then
    sudo mkdir /haplo/textidx
    sudo chown postgres:postgres /haplo/textidx
fi
if [ ! -d /opt/haplo ]; then
    sudo mkdir /opt/haplo
    sudo chown haplo:haplo /opt/haplo
fi
#
# initialize the database if it's not been done yet
#
if [ ! -d /haplo/database ]; then
    echo " *** Haplo setting up production postgresql ***"
    sudo mkdir /haplo/database
    sudo chown $USER /haplo/database
    /usr/lib/postgresql/${PG_VERSION}/bin/initdb -E UTF8 -D /haplo/database
    sudo chown -hR postgres:postgres /haplo/database
    sudo update-rc.d postgresql enable
    sudo /etc/init.d/postgresql start
    sleep 5
    DBSTARTED="y"
    cd /opt/haplo
    ./db/init_production_db.sh
    # add haplo user and permissions for production
    psql -d haplo < db/prod_perm.sql
    echo " *** Haplo production postgresql done ***"
fi

#
# if an app hasn't been created, then look to see if we can initialize one
# the test here is if we have a server certificate
#
# look for /haplo/app.values and use it if we find it
# the app initialization script will automatically start up the database
# and app if necessary
#
if [ ! -f /haplo/sslcerts/server.crt ]; then
    if [ -f /haplo/app.values ]; then
	cp /haplo/app.values /home/hbuild/app.values
	cd /home/hbuild
	./haplo-app.sh
	DBSTARTED="y"
	APPSTARTED="y"
    else
	echo " *** ERROR: no application installed and no configuration ***"
    fi
fi

#
# we must have certificates
#
[ -f /haplo/sslcerts/server.crt ] || exit 1

#
# postgres first, then haplo, and wait forever
#
if [ -z "$DBSTARTED" ]; then
    sudo /etc/init.d/postgresql start
    sleep 5
fi
if [ -z "$APPSTARTED" ]; then
    sudo su haplo -c "/opt/haplo/deploy/haplo.rc do_start"
fi
sleep Inf
