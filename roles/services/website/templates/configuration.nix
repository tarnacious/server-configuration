{ config, pkgs, lib, ... }:

{
  imports = [
    ./guest.nix
  ];

  system.stateVersion = "26.11";

  fileSystems = {
    "/var/log" = {
      device = "/dev/disk/by-label/{{ tarnbarford_logs_label }}";
      fsType = "ext4";
    };
    "/var/lib/acme" = {
      device = "/dev/disk/by-label/{{ tarnbarford_certificates_label }}";
      fsType = "ext4";
    };
    "/keys" = {
      device = "/dev/disk/by-label/{{ tarnbarford_keys_label }}";
      fsType = "ext4";
    };
    "{{ tarnbarford_web_root }}" = {
      device = "/dev/disk/by-label/{{ tarnbarford_website_label }}";
      fsType = "ext4";
    };
  };

  services.nginx = {
    enable = true;

    virtualHosts."{{ tarnbarford_fqdn }}" = {
      enableACME = true;
      forceSSL = true;

      root = "{{ tarnbarford_web_root }}";


      locations."= /atom" = {
        extraConfig = ''
          default_type application/atom+xml;
          try_files /atom.xml =404;
        '';
      };

      locations."= /rss" = {
        extraConfig = ''
          default_type application/rss+xml;
          try_files /rss.xml =404;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "{{ tarnbarford_acme_email }}";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  users.groups.{{ tarnbarford_website_group }} = {};

  users.users.{{ tarnbarford_website_user }} = {
    isSystemUser = true;
    group = "{{ tarnbarford_website_group }}";
    home = "{{ tarnbarford_website_home }}";
    createHome = true;
    shell = pkgs.bash;
  };

  services.logrotate = {
    enable = true;

    settings."/var/log/nginx/access.log" = {
      size = "{{ tarnbarford_logrotate_size }}";
      rotate = {{ tarnbarford_logrotate_rotate }};
      compress = true;
      missingok = true;
      notifempty = true;
    };

    settings."/var/log/nginx/error.log" = {
      size = "{{ tarnbarford_logrotate_size }}";
      rotate = {{ tarnbarford_logrotate_rotate }};
      compress = true;
      missingok = true;
      notifempty = true;
    };
  };

  services.journald.settings.Journal = {
    SystemMaxUse = "{{ tarnbarford_journald_system_max_use }}";
    SystemKeepFree = "{{ tarnbarford_journald_system_keep_free }}";
    MaxRetentionSec = "{{ tarnbarford_journald_max_retention }}";
  };

  systemd.tmpfiles.rules = [
    "d {{ tarnbarford_website_home }} 0755 {{ tarnbarford_website_user }} {{ tarnbarford_website_group }} -"
    "d {{ tarnbarford_web_root }} 0755 {{ tarnbarford_website_user }} {{ tarnbarford_website_group }} -"
  ];

  systemd.services.{{ tarnbarford_vm_name }}-update = {
    description = "Update and regenerate website";

    serviceConfig = {
      Type = "oneshot";
      User = "{{ tarnbarford_website_user }}";
      Group = "{{ tarnbarford_website_group }}";
      WorkingDirectory = "{{ tarnbarford_website_home }}";
    };

    script = ''
      set -euo pipefail

      if [ ! -d generator/.git ]; then
        ${pkgs.git}/bin/git clone \
          --branch {{ tarnbarford_website_repo_branch }} \
          {{ tarnbarford_website_repo }} \
          generator
      else
        cd generator
        ${pkgs.git}/bin/git fetch origin
        ${pkgs.git}/bin/git reset --hard origin/{{ tarnbarford_website_repo_branch }}
        cd ..
      fi

      if [ ! -d generator/posts/.git ]; then
        ${pkgs.git}/bin/git clone \
          --branch {{ tarnbarford_posts_repo_branch }} \
          {{ tarnbarford_posts_repo }} \
          generator/posts
      else
        cd generator/posts
        ${pkgs.git}/bin/git fetch origin
        ${pkgs.git}/bin/git reset --hard origin/{{ tarnbarford_posts_repo_branch }}
        cd ../..
      fi

      cd generator

      if [ ! -d venv ]; then
        ${pkgs.python3}/bin/python -m venv venv
      fi

      venv/bin/pip install -r requirements.txt

      venv/bin/python src/generate.py

      # Deploy generated website
      ${pkgs.rsync}/bin/rsync -a --delete \
        build/ \
        {{ tarnbarford_web_root }}
    '';
  };

  systemd.timers.{{ tarnbarford_vm_name }}-update = {
    description = "Periodically update website";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "{{ tarnbarford_timer_on_boot_sec }}";
      OnUnitActiveSec = "{{ tarnbarford_timer_on_unit_active_sec }}";
      Persistent = true;
    };
  };
}

