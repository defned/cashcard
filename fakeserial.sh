#!/bin/sh
user=belakovics

sudo socat -d -d -d -d -lf /tmp/socat pty,link=/dev/master,raw,echo=0,user=$user,group=staff pty,link=/dev/slave,raw,echo=0,user=$user,group=staff
