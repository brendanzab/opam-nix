{
  description = "Big, girthy package with a lot of dependencies";
  inputs.systems.url = "github:nix-systems/default";
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

          scope = queryToScope { } { tezos = "*"; };
          overlay = self: super: { };
        in
        scope.overrideScope overlay);

      packages = eachSystem (system: {
        default = self.legacyPackages.${system}.tezos;
      });
    };
}
