{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];


  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

  fileSystems."/mnt/owncloud" = {
    device = "https://owncloud.tarnbarford.net/remote.php/dav/files/tarn/";
    fsType = "davfs";
    options = let
      davfs2Conf = (pkgs.writeText "davfs2.conf" "secrets /etc/davfs2/secrets");
    in [ "uid=1000" "gid=100" "conf=${davfs2Conf}" "x-systemd.automount" "noauto"];
  };

  networking.extraHosts =
    ''
    192.168.122.20 api.mojoreads.local
    192.168.122.20 mojoreads.local
    192.168.122.20 www.mojoreads.local
    192.168.122.20 cms.mojoreads.local
    '';
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  security.wrappers.spice-client-glib-usb-acl-helper.source =  "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "xps-nixos";
  networking.networkmanager.enable = true;
  networking.firewall.checkReversePath = false;
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemuOvmf = true;
  hardware.nitrokey.enable = true;
  hardware.pulseaudio.enable = true;
  console.font = "latarcyrheb-sun32";
  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Berlin";
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.adb.enable = true;
  programs.seahorse.enable = true;
  sound.enable = true;
  services.davfs2.enable = true;
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.desktopManager.gnome3.enable = true;
  services.gnome3.gnome-keyring.enable = true;
  services.xserver.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    gksu
    wget
    #zoom-us
    #skype
    slack
    (import ./vim.nix)
    gawk
    nginx
    python3
    owncloud-client
    nitrokey-app
    firefox
    chromium
    pass
    git
    gnupg
    docker_compose
    fzf
    tmux
    screen
    cryptsetup
    ccrypt
    dhcpcd
    htop
    iotop
    file
    ack
    bind
    virtmanager
    pwgen

    # mail / contacts / calendars
    neomutt
    khard
    khal
    vdirsyncer
    offlineimap
    msmtp
    lynx
    urlview

    cifs_utils
    libreoffice
    ack
    rmlint
    digikam
    exfat
    filezilla
    nixops
    gnome3.networkmanagerapplet
    usbutils
    gcompris
    spice-gtk
    usbredir
    whois
    unzip
    darktable
    wireguard
    freecad
    cura
    kicad
    solvespace
  ];

  users.users.tarn = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "adbusers"
      "qemu-libvirtd"
      "libvirtd" "kvm"
      "lp"
      "usb"
      "disk"
      "davfs2"
    ];
  };

  system.stateVersion = "20.03";
}
