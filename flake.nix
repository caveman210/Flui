{
  description = "Flui - Fluid, minimalist Dynamic Island shell built with Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./package.nix { };
        flui = pkgs.callPackage ./package.nix { };
      });

      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.flui;
        in
        {
          options.programs.flui = {
            enable = lib.mkEnableOption "Flui desktop shell";

            package = lib.mkPackageOption self.packages.${pkgs.system} "flui" {
              default = [ "default" ];
            };

            systemd = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether to start Flui automatically with graphical-session.target via systemd.";
              };
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];

            systemd.user.services.flui = lib.mkIf cfg.systemd.enable {
              Unit = {
                Description = "Flui desktop shell";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
              };

              Service = {
                Type = "simple";
                ExecStart = "${cfg.package}/bin/flui";
                Restart = "on-failure";
                RestartSec = 2;
              };

              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };
        };
    };
}
