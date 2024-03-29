## Name servers

The name servers for tarnbarford.net are:

    ns1.tarnbarford.net
    ns2.tarnbarford.net

These are Debian servers running bind. They are configured by the `bind` role.

The servers can be checked with `dig`

    dig +short tarnbarford.net A @ns2.tarnbarford.net

There is another DNS server that is used resolve names internally, it is also a
Debian system running bind, how it's configured as a recursive resolver by the
`bind-recursive`.
