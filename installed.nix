{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;

  boot.kernelParams = map (c: "console=${c}") (
    [ "tty0" ]
    ++ (lib.optional (pkgs.stdenv.hostPlatform.isAarch) "ttyAMA0,115200")
    ++ (lib.optional (pkgs.stdenv.hostPlatform.isRiscV64) "ttySIF0,115200")
    ++ [ "ttyS0,115200" ]
  );

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.crypted.crypttabExtraOpts = [ "fido2-device=auto" ];
  users.users.root.initialPassword = "toor";

  disko.devices = {
    disk = {
      somedisk = {
        type = "disk";
        device = "/dev/vdb";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            encrypted = {
              size = "1G";
              content = {
                type = "luks";
                name = "crypted";
                passwordFile = builtins.toString ./password;
                postCreateHook = ''
                  PASSWORD=supersecret ${config.systemd.package}/bin/systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-somedisk-encrypted
                '';
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/encrypted";
                };
              };
            };
          };
        };
      };
    };
  };
}
