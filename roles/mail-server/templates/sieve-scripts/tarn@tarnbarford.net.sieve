require ["fileinto", "reject"];

if address :is "from" "panic@taktsoft.com"
{
    fileinto "brainsome";
}

if address :is "to" "external-services@torial.com"
{
    fileinto "brainsome";
}

if address :is "from" "piqd@noreply.github.com"
{
    fileinto "brainsome";
}

if address :is "from" "notification@mail.sandbox.billwerk.com"
{
    fileinto "brainsome";
}

if address :is "from" "nagios@bonn.taktsoft.com"
{
    fileinto "brainsome";
}

if address :is "from" "bareos@tarnbarford.net"
{
    fileinto "notifications";
}

if address :is "from" "noreply-dmarc-support@google.com"
{
    fileinto "notifications";
}


