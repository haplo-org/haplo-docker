#!/bin/bash
# Haplo Platform                                    https://haplo.org
# (c) Haplo Services Ltd 2006 - 2018            https://www.haplo.com
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
# start up a configured haplo instance
#

#
# we must have certificates
#
[ -f /haplo/sslcerts/server.crt ] || exit 1

#
# postgres first, then haplo, and wait forever
#
sudo /etc/init.d/postgresql start
sleep 5
sudo su haplo -c "/opt/haplo/deploy/haplo.rc do_start"
sleep Inf
