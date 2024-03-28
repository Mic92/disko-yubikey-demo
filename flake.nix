{
  description = "A disko yubikey example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    nixos-shell.url = "github:Mic92/nixos-shell";
    disko.url = "github:nix-community/disko";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-shell,
      disko,
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      closureInfo = pkgs.closureInfo {
        rootPaths = builtins.map (i: i.outPath) (builtins.attrValues self.inputs);
      };
    in
    {
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./installer-config.nix
          nixos-shell.nixosModules.nixos-shell
          { environment.etc."install-closure".source = "${closureInfo}/store-paths"; }
        ];
      };
      nixosConfigurations.installed = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./installed.nix
          disko.nixosModules.disko
        ];
      };

      packages.x86_64-linux.run-installer = pkgs.writeScriptBin "run-installer" ''
        #!${pkgs.stdenv.shell}
        rm -f nixos.qcow2 # contains no longer valid store paths
        USE_TMPDIR=1 TMPDIR=$(pwd) ${pkgs.nixos-shell}/bin/nixos-shell --mode mount --flake ${self}#installer
      '';
      packages.x86_64-linux.run-installed = pkgs.writeScriptBin "run-installed" ''
        #!${pkgs.stdenv.shell}
        ${pkgs.qemu_kvm}/bin/qemu-kvm \
          -enable-kvm -m 2048 \
          -usb -device "usb-host,vendorid=0x1050,productid=0x0407" \
          -nographic \
          -drive file=empty0.qcow2,if=none,id=nvm \
          -device nvme,serial=deadbeef,drive=nvm \
          -drive if=pflash,format=raw,unit=0,file="${pkgs.OVMF.fd}/FV/OVMF_CODE.fd",readonly=on # EFI firmware
      '';
    };
}
