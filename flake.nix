{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    opam2json = {
      url = "github:tweag/opam2json";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # Used for examples/tests and as a default repository
    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };

    # used for opam-monorepo
    opam-overlays = {
      url = "github:dune-universe/opam-overlays";
      flake = false;
    };
    mirage-opam-overlays = {
      url = "github:dune-universe/mirage-opam-overlays";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      opam2json,
      opam-repository,
      opam-overlays,
      mirage-opam-overlays,
      ...
    }@inputs:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);

      # The formats of opam2json output that we support
      opam2json-versions = [ "0.4" ];

      pkgs = eachSystem (system: nixpkgs.legacyPackages.${system}.extend (
        nixpkgs.lib.composeManyExtensions [
          (final: prev: {
            opam2json =
              if nixpkgs.lib.elem (prev.opam2json.version or null) opam2json-versions then
                prev.opam2json
              else
                (opam2json.overlay final prev).opam2json;
          })
        ]
      ));

      opam-nix = eachSystem (system:
        import ./src/opam.nix {
          pkgs = pkgs.${system};
          inherit
            opam-repository
            opam-overlays
            mirage-opam-overlays
            ;
        });
    in
    {
      aux = import ./src/lib.nix nixpkgs.lib;

      templates.simple = {
        description = "Simply build an opam package, preferrably a library, from a local directory";
        path = ./templates/simple;
      };
      templates.executable = {
        description = "Build an executable from a local opam package, and provide a development shell with some convinient tooling";
        path = ./templates/executable;
      };
      templates.multi-package = {
        description = "Build multiple packages from a single workspace, and provide a development shell with some convinient tooling";
        path = ./templates/multi-package;
      };
      templates.default = self.templates.simple;

      overlays = {
        ocaml-overlay = import ./src/overlays/ocaml.nix;
        ocaml-static-overlay = import ./src/overlays/ocaml-static.nix;
      };

      lib = opam-nix;

      checks = eachSystem (system:
        self.packages.${system} // (pkgs.${system}.callPackage ./examples/docfile { opam-nix = opam-nix.${system}; }).checks);

      allChecks = eachSystem (system:
        pkgs.${system}.runCommand "opam-nix-checks" { checks = nixpkgs.lib.attrValues self.checks; } "touch $out");

      packages = eachSystem (system:
        let
          pkgs = pkgs.${system};

          examples = rec {
            _0install = (import ./examples/0install/flake.nix).outputs {
              self = _0install;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems;
            };
            rocq = (import ./examples/rocq/flake.nix).outputs {
              self = rocq;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems opam-repository;
            };
            frama-c = (import ./examples/frama-c/flake.nix).outputs {
              self = frama-c;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems;
            };
            opam-ed = (import ./examples/opam-ed/flake.nix).outputs {
              self = opam-ed;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems;
            };
            opam2json = (import ./examples/opam2json/flake.nix).outputs {
              self = opam2json;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems opam2json;
            };
            ocaml-lsp = (import ./examples/ocaml-lsp/flake.nix).outputs {
              self = ocaml-lsp;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems;
            };
            opam2json-static = (import ./examples/opam2json-static/flake.nix).outputs {
              self = opam2json-static;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems opam2json;
            };
            tezos = (import ./examples/tezos/flake.nix).outputs {
              self = tezos;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems;
            };
            materialized-opam-ed = (import ./examples/materialized-opam-ed/flake.nix).outputs {
              self = materialized-opam-ed;
              opam-nix = inputs.self;
              inherit (inputs) nixpkgs systems;
            };
          };
        in
        {
          opam-nix-gen = pkgs.substitute {
            name = "opam-nix-gen";
            src = ./scripts/opam-nix-gen.in;
            dir = "bin";
            isExecutable = true;

            substitutions = [
              "--subst-var-by" "runtimeShell" pkgs.runtimeShell
              "--subst-var-by" "coreutils" pkgs.nix
              "--subst-var-by" "nix" pkgs.nix
              "--subst-var-by" "opamNix" "${self}"
            ];
          };
          opam-nix-regen = pkgs.substitute {
            name = "opam-nix-regen";
            src = ./scripts/opam-nix-regen.in;
            dir = "bin";
            isExecutable = true;

            substitutions = [
              "--subst-var-by" "runtimeShell" pkgs.runtimeShell
              "--subst-var-by" "jq" pkgs.jq
              "--subst-var-by" "opamNixGen" "${self.packages.${system}.opam-nix-gen}/bin/opam-nix-gen"
            ];
          };
        }
        // builtins.mapAttrs (_: e: e.packages.${system}.default) examples);
    };
}
