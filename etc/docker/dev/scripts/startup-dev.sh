#!/bin/bash

set -xe

# Make the databases
# for DB in dw_global dw_cluster1 dw_schwartz; do
#     echo "CREATE DATABASE $DB;" | mysql -hmysql -uroot -ppassword || true
# done
# cat $LJHOME/doc/schwartz-schema.sql | mysql -hmysql -uroot -ppassword dw_schwartz || true

# perl -I$LJHOME/extlib/ $LJHOME/bin/upgrading/update-db.pl -r -p
# perl -I$LJHOME/extlib/ $LJHOME/bin/upgrading/update-db.pl -r -p
# perl -I$LJHOME/extlib/ $LJHOME/bin/upgrading/update-db.pl -r --cluster=all
# perl -I$LJHOME/extlib/ $LJHOME/bin/upgrading/update-db.pl -r --cluster=all
# perl -I$LJHOME/extlib/ $LJHOME/bin/upgrading/texttool.pl load

# Validate that the system is set up and working correctly.
# perl -I$LJHOME/extlib/ $LJHOME/bin/checkconfig.pl

# Kick off Apache
cp /config/dreamwidth-dev.conf /etc/apache2/sites-enabled/dreamwidth.conf

ln -s /extlib/ /dw/extlib
a2dismod mpm_event
a2dissite 000-default.conf
service apache2 restart || echo "restart failed"
tail -f /var/log/apache2/error.log
