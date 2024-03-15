{ pkgs, ... }:
{
  networking.wg-quick.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      address = [ "{{ wireguard_address }}" ];

      # Match firewall allowedUDPPorts (without this wg uses random port numbers)
      listenPort = {{ wireguard_port }};

      # Important to prevent some frames being too large
      mtu = 1384;

      # Don't auto start
      autostart = false;

      # Path to the private key file.
      privateKeyFile = "/etc/wireguard/keys/private_key";

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postUp = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.1/24 -o eth0 -j MASQUERADE
        ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o eth0 -j MASQUERADE
      '';

      # Undo the above
      preDown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.1/24 -o eth0 -j MASQUERADE
        ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o eth0 -j MASQUERADE
      '';

      peers = [
        {
          # Public key of the server (not a file path).
          publicKey = "{{ wireguard_server_public_key }}";
          # Forward all the traffic via VPN.
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = "{{ wireguard_endpoint }}";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
