# Static build using the compiler from OPAM
{
  inputs.systems.url = "github:nix-systems/default";
  inputs.opam-nix.url = "github:tweag/opam-nix";
  inputs.opam2json.url = "github:tweag/opam2json";
  outputs =
    {
      self,
      nixpkgs,
      systems,
      opam-nix,
      opam2json,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      legacyPackages = eachSystem (system:
        let
          inherit (opam-nix.lib.${system}) buildOpamProject;
          pkgs = opam-nix.inputs.nixpkgs.legacyPackages.${system};
          scope = buildOpamProject { pkgs = pkgs.pkgsStatic; } "opam2json" opam2json {
            ocaml-base-compiler = "*"; # This makes opam choose the non-system compiler
          };
          overlay = self: super: {
            # Prevent unnecessary dependencies on the resulting derivation
            opam2json = super.opam2json.overrideAttrs (_: {
              removeOcamlReferences = true;
              postFixup = "rm -rf $out/nix-support";
            });
          };
        in
        scope.overrideScope overlay);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.opam2json;
      });
    };
}
