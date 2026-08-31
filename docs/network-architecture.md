## Network Architecture

The environment consists of a physical hypervisor and multiple VMs. The VMs use two separate networks:

* **IPv4:** VMs are connected to the private `virbr0` network (`192.168.122.0/24`). Each VM has a static private IPv4 address. The hypervisor provides the `192.168.122.1` gateway and performs NAT for outbound IPv4 traffic.
* **IPv6:** VMs are connected directly to the external network through the hypervisor's `br0` bridge. Each VM has a static public IPv6 address from `2a01:4f8:211:2845::/64`. IPv6 traffic does not pass through the IPv4 load balancer.

The environment has a single external IPv4 address on the hypervisor. Incoming IPv4 connections are DNATed by the hypervisor to the appropriate VM on `virbr0`. In particular, HTTP/HTTPS traffic is forwarded to the **HAProxy VM**, which then load-balances traffic to the appropriate backend VMs.

Other services such as DNS, mail, Bacula/Icinga, and the debug proxy also have specific IPv4 ports forwarded directly from the hypervisor to their respective VMs.

The **HAProxy VM is itself a guest on `virbr0`** and therefore has a private IPv4 address like the other VMs.

### Network flow

```text
                         Internet
                       /           \
                    IPv4           IPv6
                     │              │
               Hypervisor           │
              public IPv4           │
                     │              │
                  DNAT/NAT          │
                     │              │
                  virbr0            │
              192.168.122.0/24      │
                     │              │
          ┌──────────┼──────────┐   │
          │          │          │   │
       HAProxy      Mail       DNS  ... VMs
          │
          └── load balances HTTP/HTTPS
              to backend VMs

                     br0
                      │
          2a01:4f8:211:2845::/64
                      │
          ┌───────────┼───────────┐
          │           │           │
         VM1         VM2         VM3 ...
```

Each VM therefore has:

```text
ens2 → virbr0 → private/static IPv4
ens3 → br0    → public/static IPv6
```

The hypervisor's relevant addresses are:

```text
virbr0:  192.168.122.1/24
br0:     136.243.14.198/32       (public IPv4)
br0:     2a01:4f8:211:2845::3/64 (public IPv6)
```

