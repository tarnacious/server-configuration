# Setup a Certificate Authority (CA)

## Generate CA private key

Unencrypted:

  openssl genrsa -out ca.key 4096

Encrypted with aes256:

  openssl genrsa -aes256 -out ca.key 4096

## Generate CA certificate (public key)

Interactively:

  openssl req -new -x509 -sha256 -days 730 -key ca.key -out ca.crt

Non-interactively:

  openssl req -new -x509 -sha256 -days 730 -key ca.key -out ca.crt -subj "/C=DE/ST=Berlin/L=Berlin/O=tarnbarford.net/OU=tarnbarford.net/CN=ca.tarnbarford.net"

## Generate a client certificates

### Generate a private key

  openssl genrsa -out client.key 4096

### Generate a Certificate Signing Request (CSR)

Interactively:

  openssl req -new -key client.key -out client.csr

Non-interactively:

  openssl req -new -key client.key -out client.csr -subj "/C=DE/ST=Berlin/L=Berlin/O=tarnbarford.net/OU=tarnbarford.net/CN=client.tarnbarford.net"

### Sign the request with the CA key

  openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 3 -out client.crt


## Inspect key

openssl asn1parse -in privkey.pem -i 
