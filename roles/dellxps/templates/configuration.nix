{ config, pkgs, lib, nvim-config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./cachix.nix
  ];


  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_AU.utf8";
  sound.enable = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernel.sysctl = {
      "vm.max_map_count" = 262144;
    };
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    pulseaudio = {
      enable = false;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;

    firewall = {
      enable = false;
      allowedUDPPorts = [ 51820 ]; # wireguard vpn server
    };

    extraHosts = ''
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
      {{ hosts.snapper.ipv6 }} snapper
    '';
  };

  services = {
    xserver = {
      layout = "au";
      enable = true;
      xkbVariant = "";
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
      desktopManager = {
        gnome.enable = true;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    avahi = {
      enable = true;
      nssmdns = true;
    };

    printing = {
      enable = true;
      drivers = [ pkgs.gutenprint pkgs.gutenprintBin pkgs.epson-escpr];
    };
  };

  virtualisation = {
    docker = {
      enable = true;
    };

    libvirtd = {
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
  };

  security = {
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  specialisation = {
    egpu.configuration = {
      system.nixos.tags = [ "egpu" ];
      services.xserver.videoDrivers = [ "nvidia" ];
      services.xserver.displayManager.gdm.wayland = lib.mkForce false;

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        prime = {
          sync.enable = true;
          allowExternalGpu = true;
          nvidiaBusId = "PCI:6:0:0";
          intelBusId = "PCI:0:2:0";
        };
      };

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };
  };

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
    ];
  };

  programs = {
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };

  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };

    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
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
    file

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
    urlview
    khard
    msmtp
    vdirsyncer
    gthumb

    # security
    pkgs-tarn.nitrocli

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
    openjdk17
    android-studio
    gccgo

    libreoffice

    vlc
    youtube-dl

    # 3d printing
    cura
    freecad

    # text generation
    # ollama

    gnome.cheese

    nvim-config.packages.${"x86_64-linux"}.default 
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database
  # versions on your system were taken. It‘s perfectly fine and
  # recommended to leave this value at the release version of the first
  # install of this system. Before changing this value read the
  # documentation for this option (e.g. man configuration.nix or on
  # https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
