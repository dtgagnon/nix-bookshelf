{
  description = "Nix packaging flake for Bookshelf (Readarr fork)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.permittedInsecurePackages = [
              "dotnet-sdk-6.0.428"
              "aspnetcore-runtime-6.0.36"
            ];
          };
        in
        {
          bookshelf = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.bookshelf;
        }
      );

      nixosModules = {
        bookshelf = import ./module.nix self;
        default = self.nixosModules.bookshelf;
      };

      overlays.default = _final: prev: {
        bookshelf = self.packages.${prev.stdenv.hostPlatform.system}.bookshelf;
      };
    };
}
