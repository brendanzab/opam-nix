{
  description = "Build an opam project with multiple packages";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
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
          src = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
            owner = "ocaml";
            repo = "ocaml-lsp";
            rev = "c961c46fc4705b18d336ac990b9c3b39354b9d7b";
            sha256 = "U7g2ilKfd8EES1EDgy46LKkG/z1jwpd5LIkkqhe13iI=";
            fetchSubmodules = true;
          };
          inherit (opam-nix.lib.${system}) buildOpamProject';
          scope = buildOpamProject' { } src { ocaml-base-compiler = "*"; };
        in
        scope);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.ocaml-lsp-server;
      });
    };
}
