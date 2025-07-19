{
  description = "Build a package from opam-repository, using the non-system compiler";
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
          scope = queryToScope { } {
            "0install" = "*";
            # The following line forces opam to choose the compiler from opam instead of the nixpkgs one
            ocaml-base-compiler = "*";
          };
        in
        scope.overrideScope (
          final: prev: {
            "0install" = prev."0install".overrideAttrs (_: {
              preInstall = "cp _build/default/0install.install .";
              doNixSupport = false;
              removeOcamlReferences = true;
            });
          }
        ));

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}."0install";
      });
    };
}
