#!/bin/bash

# Start httpd (NOTE: Apache does not like PID files pre-existing, so kill them first)
rm -rf /run/httpd/* /tmp/httpd*
exec /usr/sbin/apachectl -DFOREGROUND