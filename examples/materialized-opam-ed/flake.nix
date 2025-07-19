{
  description = "opam-ed, without any IFD";
  nixConfig.allow-import-from-derivation = false;
  inputs.systems.url = "github:nix-systems/default";
  inputs.opam-nix.url = "github:tweag/opam-nix";
  outputs =
    {
      self,
      nixpkgs,
      systems,
      opam-nix,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      legacyPackages = eachSystem (system:
        let
          inherit (opam-nix.lib.${system}) materializedDefsToScope;
          scope = materializedDefsToScope { } ./package-defs.json;
          overlay = self: super: { };
        in
        scope.overrideScope overlay);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.opam-ed;
      });

      devShells = eachSystem (system: {
        default =
          with opam-nix.inputs.nixpkgs.legacyPackages.${system};
          mkShell { buildInputs = [ opam-nix.packages.${system}.opam-nix-gen ]; };
      });
    };
}
