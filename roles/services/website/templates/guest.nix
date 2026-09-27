{ config, pkgs, lib, ... }:

{
  boot = {
    loader.grub = { enable = true; device = "/dev/vda"; };
    initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" ];
    kernelParams = [ "console=ttyS0" ];
  };

  fileSystems = {
    "/" = { device = "/dev/disk/by-label/{{ tarnbarford_root_label }}"; fsType = "ext4"; };
  };

  networking = {
    hostName = "{{ tarnbarford_vm_name }}";
    useDHCP = false;
    nameservers = {{ tarnbarford_nameservers }};
    interfaces = {
      {{ tarnbarford_ipv4_interface }}.ipv4.addresses = [ { address = "{{ tarnbarford_ipv4 }}"; prefixLength = {{ tarnbarford_ipv4_prefix }}; } ];
      {{ tarnbarford_ipv6_interface }}.ipv6.addresses = [ { address = "{{ tarnbarford_ipv6 }}"; prefixLength = {{ tarnbarford_ipv6_prefix }}; } ];
    };
    defaultGateway = { address = "{{ tarnbarford_ipv4_gateway }}"; interface = "{{ tarnbarford_ipv4_interface }}"; };
    defaultGateway6 = { address = "{{ tarnbarford_ipv6_gateway }}"; interface = "{{ tarnbarford_ipv6_interface }}"; };
    firewall = {
      enable = true;
    };
  };

  services = {
    qemuGuest.enable = true;

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };

      hostKeys = [
        {
          path = "/keys/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/keys/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };
  };

  users.users = {
    tarn = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "{{ authorized_keys }}"
      ];
      hashedPasswordFile = "/keys/tarn-password";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
