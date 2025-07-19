{
  description = "Build a package from opam-repository, linked statically (on Linux)";
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
          inherit (opam-nix.lib.${system}) queryToScope;
          pkgs = opam-nix.inputs.nixpkgs.legacyPackages.${system};
          scope = queryToScope { pkgs = pkgs.pkgsStatic; } {
            opam-ed = "*";
            ocaml-system = "*";
          };
          overlay = self: super: {
            # Prevent unnecessary dependencies on the resulting derivation
            opam-ed = super.opam-ed.overrideAttrs (_: {
              removeOcamlReferences = true;
              postFixup = "rm -rf $out/nix-support";
            });
          };
        in
        scope.overrideScope overlay);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.opam-ed;
      });
    };
}
