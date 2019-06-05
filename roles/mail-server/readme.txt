## Mail Server

This is the public mail server used by tarnbarford.net and debugproxy.com and
as a relay server by other services and hosts on the network.



## SSL Certificates

SSL Certificates are obtained and updated from LetsEncrypt using the certbot.

## DKIM

A DKIM key needs to be generated. On this server this can be done using the
`opendkim-genkey` tool.

  opendkim-genkey -D /etc/postfix/dkim/tarnbarford.net -d tarnbarford.net -s dkim

## Database

A script to create the database and tables is copied to
`/etc/postfix/create_database.sql`. It must be run as root.

  mysql < /etc/postfix/create_database.sql

### Adding domains

Domains can be added by inserting rows in the domains in the vmail database.

  insert into domains (domain) values ('tarnbarford.net');

### Adding users

A password hash can be created using the `doveadm` tool.

```
doveadm pw -s SHA512-CRYPT
```

```
insert into accounts (username, domain, password, quota, enabled, sendonly) values
('tarn', 'tarnbarford.net', '{SHA512-CRYPT}..', 1024, true, false);
```

### Adding alias

```
insert into aliases (source_username, source_domain, destination_username, destination_domain, enabled) values ('postmaster', 'tarnbarford.net', 'tarn', 'tarnbarford.net', true);
```
