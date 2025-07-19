# We can build GUI stuff!
# Don't try to build it statically though
{
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

          pkgs' = if pkgs.stdenv.isDarwin then pkgs else pkgs.pkgsStatic;

          scope = queryToScope { } {
            frama-c = "*";
            alt-ergo = "2.4.1";
            lablgtk3 = "*"; # Use lablgtk3 when appropriate
            lablgtk3-sourceview3 = "*";
            ocaml-base-compiler = "*";
          };

          overlay = self: super: {
            frama-c = super.frama-c.overrideAttrs (oa: {
              buildInputs = oa.buildInputs ++ [ pkgs'.freetype ];
              nativeBuildInputs = oa.nativeBuildInputs ++ [ pkgs.makeWrapper ];

              NIX_LDFLAGS =
                "-L${pkgs'.fontconfig.lib}/lib -L${pkgs'.pkgsStatic.expat}/lib -lfontconfig -lfreetype -lexpat";
              postInstall = ''
                for i in $(find $out/bin -type f); do
                  wrapProgram "$i" --prefix OCAMLPATH : "$OCAMLPATH"
                done
              '';
            });
          };
        in
        scope.overrideScope overlay);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}."0install";
      });
    };
}
