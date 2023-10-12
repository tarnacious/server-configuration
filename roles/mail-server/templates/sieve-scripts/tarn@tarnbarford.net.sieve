require ["fileinto", "reject"];

if address :is "from" "bareos@tarnbarford.net"
{
    fileinto "notifications";
}

if address :is "from" "noreply-dmarc-support@google.com"
{
    fileinto "notifications";
}


