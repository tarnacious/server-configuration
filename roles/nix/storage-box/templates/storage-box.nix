{ pkgs, ... }:
{
    fileSystems."/mnt/storage-box" = {
    device = "{{ storage_box.address }}";
    fsType = "cifs";
    options = [ "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "credentials=/etc/nixos/storage-box-secrets" ];
  };
}
