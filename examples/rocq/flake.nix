{
  description = "Build a rocq (coq) package";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.systems.url = "github:nix-systems/default";
  inputs.opam-nix.url = "github:tweag/opam-nix";
  inputs.opam-repository.url = "github:ocaml/opam-repository";
  inputs.opam-repository.flake = false;
  outputs =
    {
      self,
      nixpkgs,
      systems,
      opam-nix,
      opam-repository,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      legacyPackages = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          opam-coq-archive = pkgs.fetchFromGitHub {
            "owner" = "rocq-prover";
            "repo" = "opam";
            "rev" = "91321f17b5fe3de5b075481ff5a9d1de2c84dd92";
            "hash" = "sha256-VdK5B+HJ7rT4hkCZeT0ZKRutmLZ1J/jk0FZlgB0A9rw=";
          };
          inherit (opam-nix.lib.${system}) queryToScope;
          scope =
            queryToScope
              {
                repos = [
                  "${opam-repository}"
                  "${opam-coq-archive}/extra-dev"
                ];
              }
              {
                rocq-prover = "*";
                coq-inf-seq-ext = "*";
                ocaml-base-compiler = "*";
              };
        in
        scope);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.coq-inf-seq-ext;
      });
    };
}
