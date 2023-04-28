# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{ imports = [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./vim.nix
      ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  # Configure keymap in X11
  services.xserver = {
    layout = "au";
    enable = true;
    xkbVariant = "";
  };

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.kernel.sysctl =
    {
      "vm.max_map_count" = 262144;
    };

  networking.extraHosts =
    ''
      127.0.0.1 ybs.local
      127.0.0.1 m.ybs.local
      127.0.0.1 api.ybs.local
      127.0.0.1 cms.ybs.local
      127.0.0.1 admin.ybs.local
      127.0.0.1 rabbitmq.ybs.local
      127.0.0.1 logging.ybs.local
      127.0.0.1 products.ybs.local
      127.0.0.1 media.ybs.local
      127.0.0.1 book-data.ybs.local

      {{ hosts.hypervisor.ipv6 }} hypervisor
      {{ hosts.bacula.ipv6 }} bacula bacula.tarnbarford.net
      {{ hosts.monitoring.ipv6 }} monitoring monitoring.tarnbarford.net
      {{ hosts.load_balancer.ipv6 }} load-balancer load-balancer.tarnbarford.net
      {{ hosts.tarnbarford.ipv6 }} tarnbarford tarnbarford.net
      {{ hosts.bab_website.ipv6 }} bab-website
      {{ hosts.owncloud.ipv6 }} owncloud owncloud.tarnbarford.net
      {{ hosts.mail_server.ipv6 }} mail-server mail.tarnbarford.net
      {{ hosts.debugproxy.ipv6 }} debugproxy debugproxy.com
      {{ hosts.icinga.ipv6 }} icinga icinga.tarnbarford.net
      {{ hosts.ns1.ipv6 }} ns1 ns1.tarnbarford.net
      {{ hosts.ns2.ipv6 }} ns2 ns2.tarnbarford.net
    '';

  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.ovmf.enable = true;

  # Setup keyfile
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null;
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
      ];
      gtkUsePortal = true;
    };
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via
  # wpa_supplicant.

  # Configure network proxy if necessary networking.proxy.default =
  # "http://user:password@proxy:port/"; networking.proxy.noProxy =
  # "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.utf8";

  # Enable the X11 windowing system.



  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint pkgs.gutenprintBin ];

  # services.gnome.gnome-keyring.enable = true;

  # Enable sound with pipewire.
  sound.enable = true; hardware.pulseaudio.enable = false;
  security.rtkit.enable = true; services.pipewire = {
    enable = true; alsa.enable = true; alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this jack.enable =
    #true;

    # use the example session manager (no others are packaged yet so
    # this is enabled by default, no need to redefine it in your config
    # for now)
    #media-session.enable = true;
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tarn = {
    isNormalUser = true;
    description = "tarn";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "qemu-libvirtd"
      "libvirtd"
      "kvm"
    ];

    packages = with pkgs; [
      firefox
    #  thunderbird
    ];
  };

  # List packages installed in system profile. To search, run: $ nix
  # search wget
  programs.gnupg.agent = {
	enable = true;
	enableSSHSupport = true;
  };
  environment.systemPackages = with pkgs; [

  skypeforlinux
  google-chrome

  # standard tools
  gnupg
  pass
  git
  tmux
  wget
  bind
  htop
  cloc
  pwgen
  zip
  unzip

  # gui tools
  filezilla
  vscode
  pinta

  # mail / contacts / calendars
  neomutt
  offlineimap
  khard
  msmtp
  vdirsyncer

  # notes
  joplin
  joplin-desktop

  # work
  slack

  # owncloud
  owncloud-client

  # virtualisation
  virtmanager

  jetbrains.idea-community
  maven
  openjdk8
  openjdk17

  libreoffice

  vlc
  youtube-dl

  # 3d printing
  cura
  freecad



  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions. programs.mtr.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon. services.openssh.enable = true;

  # Open ports in the firewall. networking.firewall.allowedTCPPorts = [
  # ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the
  # firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database
  # versions on your system were taken. It‘s perfectly fine and
  # recommended to leave this value at the release version of the first
  # install of this system. Before changing this value read the
  # documentation for this option (e.g. man configuration.nix or on
  # https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
