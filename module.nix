flake:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.bookshelf;
  servarr = import ./settings-options.nix { inherit lib pkgs; };
in
{
  options = {
    services.bookshelf = {
      enable = lib.mkEnableOption "Bookshelf, a Usenet/BitTorrent ebook manager (Readarr fork)";

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/bookshelf/";
        description = "The directory where Bookshelf stores its data files.";
      };

      package = lib.mkPackageOption pkgs "bookshelf" {
        default = [ flake.packages.${pkgs.stdenv.hostPlatform.system}.bookshelf ];
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open ports in the firewall for Bookshelf.";
      };

      settings = servarr.mkServarrSettingsOptions "bookshelf" 8787;

      environmentFiles = servarr.mkServarrEnvironmentFiles "bookshelf";

      hardcover = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hardcover integration by setting HARDCOVER=true environment variable.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "bookshelf";
        description = "User account under which Bookshelf runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "bookshelf";
        description = "Group under which Bookshelf runs.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.settings."10-bookshelf".${cfg.dataDir}.d = {
      inherit (cfg) user group;
      mode = "0700";
    };

    systemd.services.bookshelf = {
      description = "Bookshelf";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment =
        servarr.mkServarrSettingsEnvVars "BOOKSHELF" cfg.settings
        // lib.optionalAttrs cfg.hardcover { HARDCOVER = "true"; };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        EnvironmentFile = cfg.environmentFiles;
        ExecStart = "${cfg.package}/bin/Readarr -nobrowser -data='${cfg.dataDir}'";
        Restart = "on-failure";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.settings.server.port ];
    };

    users.users = lib.mkIf (cfg.user == "bookshelf") {
      bookshelf = {
        description = "Bookshelf service";
        home = cfg.dataDir;
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "bookshelf") {
      bookshelf = { };
    };
  };
}
