{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-iceshelf-sc.url = "github:nofishleft/nixpkgs/iceshelf_storage_class";
    lvm-homepage = {
      url = "github:nofishleft/lvm-homepage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wg-homepage = {
      url = "github:nofishleft/wg-homepage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, lvm-homepage, wg-homepage, ...}@inputs: {
    nixosConfigurations.rishaan-nas = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ...}: {
          nixpkgs.overlays = [
            (final: prev: {
              iceshelf = (import inputs.nixpkgs-iceshelf-sc {
                system = "x86_64-linux";
              }).iceshelf;
            })
          ];
        })
        lvm-homepage.nixosModules.default
        wg-homepage.nixosModules.default
        ./configuration.nix
        sops-nix.nixosModules.sops
      ];
    };
  };
}
