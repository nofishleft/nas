{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "r8125" "dm-raid" "raid10" ];
  boot.initrd.services.lvm.enable = true;
  boot.kernelModules = [];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    r8125
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b501a3bc-eb5c-4651-a5e1-24132a7ed981";
      fsType = "ext4";
    };
  fileSystems."/storage" = {
    device = "/dev/pool/raid10_lv";
    fsType = "ext4";
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
