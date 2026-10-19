{ config, pkgs, lib, ... }:

{
  imports = [
    ./guest.nix
  ];

  system.stateVersion = "26.11";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    ocis_70-bin
  ];

  fileSystems = {
    "/var/log" = { device = "/dev/disk/by-label/logs"; fsType = "ext4"; };
    "/var/lib/caddy" = { device = "/dev/disk/by-label/certificates"; fsType = "ext4"; };
    "/var/lib/ocis" = { device = "/dev/disk/by-label/data"; fsType = "ext4"; };
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

    journald = {
      settings = {
        Journal = {
          SystemMaxUse = "700M";
          SystemKeepFree = "200M";
          Storage = "persistent";
        };
      };
    };

    ocis = {
      enable = true;
      address = "127.0.0.1";
      port = 9200;
      url = "https://{{ hosts.cloud.fqdn }}";
      environment = {
        PROXY_TLS = "false";
        PROXY_ENABLE_BASIC_AUTH = "true";
      };
      package = pkgs.ocis_81-bin;
    };

    caddy = {
      enable = true;
      virtualHosts."{{ hosts.cloud.fqdn }}".extraConfig = ''
        reverse_proxy 127.0.0.1:9200
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
