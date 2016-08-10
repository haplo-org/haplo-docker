#!/bin/bash
# Haplo Platform                                     http://haplo.org
# (c) Haplo Services Ltd 2006 - 2016    http://www.haplo-services.com
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
# This script runs the haplo test suite
#
# The test needs to be run from the build area, not the installed area,
# but the Docker build cleaned that up for us so we need to modify the
# environment to run correctly
#

if [ ! -d /home/hbuild/haplo ]; then
    exit 2
fi
cd /home/hbuild/haplo

#
# we need to pick up the installed jruby and the installed jars
# note that symlinking jruby doesn't work correctly
#
cp /opt/haplo/target/classpath.txt target/classpath.txt
sed -i s:~/haplo-dev-support/:/opt/haplo/: config/paths-Linux.sh

#
# create a temporary postgres instance
# and start it up
#
rm -fr /home/hbuild/haplo-dev-support/pg
mkdir -p /home/hbuild/haplo-dev-support/pg
/usr/lib/postgresql/${PG_VERSION}/bin/initdb -E UTF8 -D /home/hbuild/haplo-dev-support/pg
sudo chmod a+rwx /var/run/postgresql
# stale locks can prevent startup, so make sure they are removed
sudo rm -f /var/run/postgresql/.s.*
/usr/lib/postgresql/${PG_VERSION}/bin/pg_ctl -D /home/hbuild/haplo-dev-support/pg -l logfile start

#
# create test certificates
# (note: this can fail, in which case simply run it again)
#
deploy/setup_developer_vm

#
# finally, run the test
#
script/test
