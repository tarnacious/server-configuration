{ pkgs, trains, ... }: 
let 
  environment = pkgs.writeTextFile {
  name = "train-tracker-environment";
  text = ''
export HTML_PATH=/var/www/trains/ 
export DATABASE_PATH=/var/lib/train-tracker/trains.db
export TOKEN_PATH=/var/lib/train-tracker/token.json
  '';
  };
  trainspkg = trains.packages.${"x86_64-linux"}.default;
in
{
  imports = [ 
      ./hardware-configuration.nix 
    ]; 

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  boot.kernelParams = [
     "console=ttyS0,115200"
     "console=tty1"
  ];

  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      charset utf-8;
      source_charset utf-8;
    '';
    virtualHosts."trains.tarnbarford.net" = {
      addSSL = true;
      enableACME = true;
      root = "/var/www/trains";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "tarn@tarnbarford.net";
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 */6 * * *      root    . ${environment}; ${trainspkg}/bin/train-tracker"
    ];
  };

  networking = {
    hostName = "train-tracker"; 
    interfaces = {
      ens2 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.122.24";
          prefixLength = 24;
        }];
      };
      
      ens3 = {
        useDHCP = false;
        ipv6.addresses = [{
          address = "2a01:4f8:211:2845::24";
          prefixLength = 64;
        }];
      };
    };
    defaultGateway = "192.168.122.1";

    defaultGateway6 = {
      address = "2a01:4f8:211:2845::3";
      interface = "ens3";
    };
    nameservers = ["1.1.1.1" "8.8.8.8"];
    networkmanager.enable = true;
    firewall = { 
      allowedTCPPorts = [ 22 80 443 ];
      enable = true;
    };
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
      trainspkg
    ];
  };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 4*1024;
  } ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "23.11"; 
}
