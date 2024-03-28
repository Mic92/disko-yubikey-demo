# disko-install + yubikey demo

## Requirements

- A yubikey connected to your computer with the PIN for fido set up

## Play through the demo

In this flake we have two VMs:

- an installer
- the installed machine

1. Run the installer:

```console
$ nix run .#run-installer
```

2. Login as "root" with an empty password

3. Run `do-install`

Afterwards nixos install is installed in the current directory to an image called `empty0.qcow`.
The installer will automaticall shutdown

3. The installed VM afterwards can be run like this:

```console
$ nix run .#run-installed
```
