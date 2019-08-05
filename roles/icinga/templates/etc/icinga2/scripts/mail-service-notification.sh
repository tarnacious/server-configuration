template=`cat <<TEMPLATE
***** Icinga  *****

Notification Type: $NOTIFICATIONTYPE

Service: $SERVICEDESC
Host: $HOSTALIAS
Address: $HOSTADDRESS
State: $SERVICESTATE

Date/Time: $LONGDATETIME

Additional Info: $SERVICEOUTPUT

Comment: [$NOTIFICATIONAUTHORNAME] $NOTIFICATIONCOMMENT
TEMPLATE
`

(echo "Subject: $NOTIFICATIONTYPE - $HOSTDISPLAYNAME - $SERVICEDISPLAYNAME IS $SERVICESTATE"; /usr/bin/printf "%b" "$template") | sendmail -f icinga@tarnbarford.net $USEREMAIL
