Name servers

The authoritative name servers for tarnbarford.net are:

ns1.tarnbarford.net
ns2.tarnbarford.net

Both are Debian servers running BIND9 and are configured by the bind role.

BIND uses separate public and trusted views. Public clients receive authoritative, non-recursive DNS service, while trusted clients receive additional internal records used by services such as the mail server.

The authoritative servers can be checked with `dig`, for example:

```
dig +short tarnbarford.net A @ns1.tarnbarford.net
dig +short tarnbarford.net A @ns2.tarnbarford.net
```

Check that the servers are authoritative for the zone:

```
dig +noall +answer +authority tarnbarford.net @ns1.tarnbarford.net
dig +noall +answer +authority tarnbarford.net @ns2.tarnbarford.net
```

The internal zone is only available to trusted clients:

```
dig +short internal.tarnbarford.net A @ns1.tarnbarford.net
dig +short internal.tarnbarford.net A @ns2.tarnbarford.net
```

The authoritative servers are non-recursive. A query for an unrelated domain should not be resolved recursively:

```
dig +noall +comments example.com @ns1.tarnbarford.net
dig +noall +comments example.com @ns2.tarnbarford.net
```

