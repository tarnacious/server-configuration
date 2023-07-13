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

      peers = [
        {
          # Public key of the server (not a file path).
          publicKey = "{{ wireguard_server_public_key }}";

          # Forward all the traffic via VPN.
          allowedIPs = [ "0.0.0.0/0" "::/0" ];

          # Set this to the server IP and port.
          # ToDo: route to endpoint not automatically configured
          # https://wiki.archlinux.org/index.php/WireGuard#Loop_routing
          # https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577
          endpoint = "{{ wireguard_endpoint }}";

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
