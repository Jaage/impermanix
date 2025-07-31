{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland.url = "github:hyprwm/Hyprland";
    nixvim.url = "github:Jaage/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-fonts.url = "github:Jaage/nix-fonts";
  };
  outputs =
    inputs@{ self, nixpkgs, ... }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          inputs.impermanence.nixosModules.impermanence
        ];
      };
    };
}
