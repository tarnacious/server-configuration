{ config, pkgs, lib, ... }:

{
  boot = {
    loader.grub = { enable = true; device = "/dev/vda"; };
    initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" ];
    kernelParams = [ "console=ttyS0" ];
  };

  fileSystems = {
    "/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  };

  networking = {
    hostName = "owncloud";
    useDHCP = false;
    nameservers = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    interfaces = {
      enp0s2.ipv4.addresses = [ { address = "{{ hosts.cloud.ipv4 }}"; prefixLength = 24; } ];
      enp0s3.ipv6.addresses = [ { address = "{{ hosts.cloud.ipv6 }}"; prefixLength = 64; } ];
    };
    defaultGateway = { address = "{{ gateway4 }}"; interface = "enp0s2"; };
    defaultGateway6 = { address = "{{ gateway6 }}"; interface = "enp0s3"; };
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
    };
  };

  users.users = {
    root.hashedPassword = "{{ hosts.cloud.root_password_hash }}";
    tarn = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "{{ authorized_keys }}"
      ];
      hashedPassword = "{{ hosts.cloud.root_password_hash }}";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
