$TTL    604800
@       IN      SOA     debugproxy.com. hello.debugproxy.com. (
                              4         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
; name servers
@               IN      NS      ns1.tarnbarford.net.
@               IN      NS      ns2.tarnbarford.net.
; a records
@               IN      A       136.243.14.198
www             IN      A       136.243.14.198
@               IN      MX      1  mail.tarnbarford.net.
                IN      TXT     "v=spf1 mx a -all"
dkim._domainkey IN      TXT     ("v=DKIM1; k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA01OE1kV7QCO9NvLc68pwfRYpPCEkJ0zfP+D8n3XVCIPsZAKoznnjXcN4c2YcwXIjgT7ztg/w8cIeg3zDhVj2mA/D56y9A1Ys/E8KASoJwjxI2X7SKAEfjGBkh/EXEGi8h2VHjmoIAJY9Zh0wglVW/QsfoUWw0olS9KCCyDrdVYVrmLu72tkvboox/BbmxGbQCd" "6EqLDqPiuoBuLTggBdmmpUy9tLmYTXhNGa+0Z9hqLzykzM2vD/WoJ4JoJzWxOitchoXf35n4jDgU+3NkzNwI90QaUssRUSIn5C8Wk7lkAkIM4Lo31cpEAYwqiXHi0RBTbFFEy+7HteYE90AQ+9dwIDAQAB")

