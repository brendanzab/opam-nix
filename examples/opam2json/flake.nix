{
  description = "Build an opam project not in the repo, using sane defaults";
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
          scope = buildOpamProject { } "opam2json" opam2json {
            ocaml-system = "*";
          };
        in
        scope);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.opam2json;
      });
    };
}
