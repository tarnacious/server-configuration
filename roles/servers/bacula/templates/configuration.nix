{ pkgs, ... }: let 
  myscript = pkgs.writeShellApplication {
  name = "send-mail";
  runtimeInputs = [
    pkgs.msmtp
  ];
  text = ''
recipient=$2
subject=$1
body=$(</dev/stdin)

# Construct the email headers
email_content="From: Bacula <bareos@tarnbarford.net>
To: $recipient
Subject: $subject

$body"

echo "$email_content" | ${pkgs.msmtp}/bin/sendmail -t
  '';
  };
in
{
  imports =
    [ 
      ./hardware-configuration.nix ]; nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  boot.kernelParams = [
     "console=ttyS0,115200"
     "console=tty1"
  ];

  services.postgresql = {
    enable = true;
    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      '';
  };

  fileSystems."/mnt/backup" = {
    device = "//u198293.your-storagebox.de/backup";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},credentials=/etc/bacula/storagebox-credentials"];
  };

  programs.msmtp = {
    enable = true;
    accounts = {
      default = {
        auth = true;
        tls = true;
        port = 587;
        # try setting `tls_starttls` to `false` if sendmail hangs
        from = "bareos@tarnbarford.net";
        host = "mail.tarnbarford.net";
        user = "bareos@tarnbarford.net";
        passwordeval = "cat /etc/bacula/smtp-password";
      };
    };
  };

  networking = {
    hostName = "bacula"; 
    interfaces = {
      ens3 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.122.21";
          prefixLength = 24;
        }];
      };
      
      ens4 = {
        useDHCP = false;
        ipv6.addresses = [{
          address = "2a01:4f8:211:2845::21";
          prefixLength = 64;
        }];
      };
    };
    defaultGateway = "192.168.122.1";

    defaultGateway6 = {
      address = "2a01:4f8:211:2845::3";
      interface = "ens4";
    };
    nameservers = ["1.1.1.1" "8.8.8.8"];
    networkmanager.enable = true;
    firewall = { 
      allowedTCPPorts = [ 22 5432 9103 9101 ];
      enable = true;
    };

    extraHosts = ''
    '';
#      127.0.0.1 bacula.tarnbarford.net 
#      ::1 bacula.tarnbarford.net 
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    layout = "au";
    xkbVariant = "";
  };

  users.users.tarn = {
    isNormalUser = true;
    description = "tarn";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  environment = {
    systemPackages = with pkgs; [
      vim
      python3
      postgresql
      bacula
      mailutils
      cifs-utils
    ] ++ [ myscript ];

    interactiveShellInit = ''
      alias bconsole="sudo bconsole -c /etc/bacula/bconsole.conf"
      '';
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  systemd.services.bacula-dir = {
    enable = true;
    description = "Bacula Director";
    serviceConfig = {
      ExecStart = "${pkgs.bacula}/bin/bacula-dir -f -d 99 -c /etc/bacula/bacula-dir.conf";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.bacula-sd = {
    enable = true;
    description = "Bacula Storage Daemon";
    serviceConfig = {
      ExecStart = "${pkgs.bacula}/bin/bacula-sd -f -c /etc/bacula/bacula-sd.conf";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.bacula-fd = {
    enable = true;
    description = "Bacula File Daemon";
    serviceConfig = {
      ExecStart = "${pkgs.bacula}/bin/bacula-fd -f -c /etc/bacula/bacula-fd.conf";
    };
    wantedBy = [ "multi-user.target" ];
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
