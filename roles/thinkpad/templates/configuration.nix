{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./wg-quick.nix
    ./storage-box.nix
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.nixos-cuda.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  virtualisation.spiceUSBRedirection.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  hardware.opengl = {
    # removed upgrading to nixos 24.11
    #driSupport = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver = {
    enable = true;
    libinput = {
      enable = true;
      touchpad = {
        tapping = false; # disables tap-to-click
        disableWhileTyping = true;
      };
    };
    xkb = {
      layout = "au";
    };

  };


  specialisation = {
    external-cuda.configuration = {
      system.nixos.tags = [ "external-cuda" ];
      hardware.nvidia = {
        open = true;
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
      };
      services.open-webui = {
        enable = true;
        environment = {
          OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        };
      };
    };
    external-gpu.configuration = {
      system.nixos.tags = [ "external-gpu" ];
      services.xserver.videoDrivers = [ "nvidia" ];
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

  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;
  };

  networking.extraHosts =
    ''
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
      swtpm.enable = true;
      runAsRoot = true;
    };
  };

  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  networking.hostName = "nixos";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.printing.drivers = [
    pkgs.gutenprint
    pkgs.gutenprintBin
    pkgs.epson-escpr
  ];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
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

    # gui tools
    filezilla
    vscode
    pinta

    # mail / contacts / calendars
    neomutt
    offlineimap
    khard
    khal
    msmtp
    vdirsyncer

    # wayland
    wl-clipboard

    # notes
    joplin-cli

    # owncloud
    owncloud-client

    # virtualisation
    virt-manager

    vlc
    freecad
    opencode
    nvim-config-pkg


    llm-agents.pi

    # needed for installing pi plugins
    nodejs
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

  environment.interactiveShellInit = ''
    alias vim='nvim'
  '';

}
