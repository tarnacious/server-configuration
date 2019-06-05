#!/bin/sh
template=`cat <<TEMPLATE
***** Icinga  *****

Notification Type: $NOTIFICATIONTYPE

Host: $HOSTALIAS
Address: $HOSTADDRESS
State: $HOSTSTATE

Date/Time: $LONGDATETIME

Additional Info: $HOSTOUTPUT

Comment: [$NOTIFICATIONAUTHORNAME] $NOTIFICATIONCOMMENT
TEMPLATE
`

(echo "Subject: $NOTIFICATIONTYPE - $HOSTDISPLAYNAME is $HOSTSTATE"; /usr/bin/printf "%b" "$template") | sendmail $USEREMAIL
