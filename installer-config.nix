{ pkgs, lib, ... }:
{
  nix = {
    nixPath = [ "nixpkgs=${pkgs.path}" ];
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    registry.nixpkgs.to = {
      type = "path";
      path = pkgs.path;
    };
  };
  virtualisation.cores = 4;
  virtualisation.memorySize = 4096;
  virtualisation.diskSize = 20 * 1024;
  virtualisation.emptyDiskImages = [ 16000 ]; # 16GB
  virtualisation.qemu.options = [
    "-usb" "-device" "usb-host,vendorid=0x1050,productid=0x0407"
  ];
  services.getty.autologinUser = lib.mkForce "root";

  # Yubikey-agent expects pcsd to be running in order to function.
  services.pcscd.enable = true;

  environment.systemPackages = [
    pkgs.yubikey-manager
    pkgs.vim
    pkgs.cryptsetup
    (pkgs.writeShellScriptBin "do-install" ''
      set -euxo pipefail
      ${pkgs.disko}/bin/disko-install --debug --flake ${./.}#installed --disk somedisk /dev/vdb
      poweroff
    '')
  ];
}
