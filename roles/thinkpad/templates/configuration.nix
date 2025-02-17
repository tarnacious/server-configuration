{ config, pkgs, lib, ... }:

{ imports = [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./cachix.nix
      ./vim.nix
      ./wg-quick.nix
      ./storage-box.nix
      ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  virtualisation.spiceUSBRedirection.enable = true;

  # Configure keymap in X11
  services.xserver = {
    enable = true;
    xkb = {
      variant = "";
      layout = "au";
    };
  };

  # Firmware updates
  services.fwupd.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  hardware.opengl = {
    # removed upgrading to nixos 24.11
    #driSupport = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  specialisation = {
    external-cuda.configuration = {
      system.nixos.tags = [ "external-cuda" ];
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        open = true;
      };
    };
    external-gpu.configuration = {
      system.nixos.tags = [ "external-gpu" ];
      services.xserver.videoDrivers = [ "nvidia" ];
      services.xserver.displayManager.gdm.wayland = lib.mkForce false;
      services.xserver.enable = true;
      boot.kernelParams = [ "module_blacklist=i915" ];
      hardware.nvidia = {
        open = true;
        nvidiaSettings = true;
        modesetting.enable = true;
        powerManagement.enable = false;
        prime = {
          sync = {
            enable = true;
          };
          offload = {
            enable = false;
          };
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:82:0:0";
        };
      };
    };
  };

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
      {{ hosts.bacula.ipv6 }} bacula
      {{ hosts.monitoring.ipv6 }} monitoring
      {{ hosts.load_balancer.ipv6 }} load-balancer
      {{ hosts.tarnbarford.ipv6 }} tarnbarford
      {{ hosts.bab_website.ipv6 }} bab-website
      {{ hosts.owncloud.ipv6 }} owncloud
      {{ hosts.mail_server.ipv6 }} mail-server
      {{ hosts.debugproxy.ipv6 }} debugproxy
      {{ hosts.icinga.ipv6 }} icinga
      {{ hosts.ns1.ipv6 }} ns1
      {{ hosts.australia.ipv6 }} australia
    '';

  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "suspend";
    onBoot = "ignore";
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
      swtpm.enable = true;
      runAsRoot = true;
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Hack" "Terminus" "Monoid" "JetBrainsMono" ]; })
  ];

  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };

    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
    };
  };

  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;  # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.tctiEnvironment.enable = true;  # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables

  # Setup keyfile
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null;
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

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.printing.drivers = [ pkgs.gutenprint pkgs.gutenprintBin pkgs.epson-escpr];

  # services.gnome.gnome-keyring.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
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
      "tss"
    ];

    packages = with pkgs; [
      firefox
    #  thunderbird
    ];
  };

  programs = {
    gnome-terminal.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    bash.shellAliases = {
      myvim = "nix run ~/projects/vim2/ --";
    };
  };


  environment.systemPackages = with pkgs; [
    skypeforlinux
    google-chrome

    # standard tools
    gnupg
    pass
    git
    git-lfs
    tmux
    wget
    bind
    htop
    cloc
    pwgen
    zip
    unzip
    screen
    openssl
    inetutils

    # conversion tools
    imagemagick
    pandoc
    ffmpeg

    # system tools
    pciutils
    lshw
    cachix

    # gui tools
    filezilla
    vscode
    pinta

    # mail / contacts / calendars
    neomutt
    offlineimap
    # urlview
    # Consider switching to an alternative such as `pkgs.extract_url` or `pkgs.urlscan`.
    khard
    khal
    msmtp
    vdirsyncer

    # security
    #pkgs-tarn.nitrocli

    # wayland
    wl-clipboard

    # notes
    joplin
    joplin-desktop

    # work
    slack

    # owncloud
    owncloud-client

    # virtualisation
    virt-manager

    jetbrains.idea-community
    maven
    openjdk8
    openjdk17

    libreoffice

    vlc
    # youtube-dl
    # youtube-dl is unmaintained, migrate to yt-dlp, if possible

    # 3d printing
    # disable for now, upgrading to 24.11
    # cura
    freecad
  ];

  networking.firewall = {
    enable = false;
    allowedUDPPorts = [ 51820 ]; # wireguard vpn server
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database
  # versions on your system were taken. It‘s perfectly fine and
  # recommended to leave this value at the release version of the first
  # install of this system. Before changing this value read the
  # documentation for this option (e.g. man configuration.nix or on
  # https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

