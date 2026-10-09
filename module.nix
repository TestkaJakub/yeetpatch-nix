# NixOS module: programs.yeetpatch
#
# Bakes your settings into the `yeetpatch` command as defaults. Every value
# can still be overridden per run, e.g.  INSTALL_DIR=/elsewhere yeetpatch install
self:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.yeetpatch;

  inherit (lib)
    mkOption mkEnableOption mkIf types optional
    concatStringsSep mapAttrsToList filterAttrs escapeShellArg;

  # Paths are plain strings on purpose: types.path would copy them into the
  # Nix store. They must be absolute ($HOME / ~ are not expanded).
  pathOpt = description: mkOption {
    type    = types.nullOr types.str;
    default = null;
    example = "/home/alice/Games/VotV";
    inherit description;
  };

  settings = filterAttrs (_: v: v != null) {
    INSTALL_DIR  = cfg.installDir;
    EXE_PATH     = cfg.exePath;
    CACHE_DIR    = cfg.cacheDir;
    SAVEGAME_DIR = cfg.saveGameDir;
    BACKUPS_DIR  = cfg.backupsDir;
    NOTICE_URL   = cfg.noticeUrl;
  } // cfg.extraEnvironment;

  configured =
    if settings == { } then cfg.package
    else pkgs.symlinkJoin {
      name              = "yeetpatch-configured";
      paths             = [ cfg.package ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/yeetpatch ${concatStringsSep " "
          (mapAttrsToList (n: v: "--set-default ${n} ${escapeShellArg v}") settings)}
      '';
      inherit (cfg.package) meta;
    };

  # Keeps the terminal open after the patcher exits, so its output stays readable
  updateAndWait = pkgs.writeShellScript "yeetpatch-update" ''
    ${configured}/bin/yeetpatch update
    echo
    read -rp "Press Enter to close…" _
  '';

  launcherEntry = pkgs.makeDesktopItem {
    name        = "yeetpatch";
    desktopName = "Update VotV";
    comment     = "Patch Voices of the Void to the latest version";
    icon        = "system-software-update";
    categories  = [ "Game" ];
    exec =
      if cfg.launcher.terminalCommand == null
      then "${updateAndWait}"
      else "${cfg.launcher.terminalCommand} ${updateAndWait}";
    terminal = cfg.launcher.terminalCommand == null;
  };
in
{
  options.programs.yeetpatch = {
    enable = mkEnableOption "YeetPatch, the Voices of the Void patcher";

    package = mkOption {
      type        = types.package;
      default     = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "yeetpatch-nix.packages.\${system}.default";
      description = "The yeetpatch package to use.";
    };

    installDir  = pathOpt "Destination folder for `yeetpatch install` (package default: ~/Games/VotV).";
    exePath     = pathOpt "Path to VotV.exe, so `yeetpatch update` works without an argument.";
    cacheDir    = pathOpt "desync cache folder. Speeds up reinstalls and version switches, costs disk space.";
    saveGameDir = pathOpt "Saves folder to back up as .tar.gz before patching. Unset = no backups.";
    backupsDir  = pathOpt "Where save backups go (package default: ~/.local/share/yeetpatch/backups).";

    noticeUrl = mkOption {
      type        = types.nullOr types.str;
      default     = null;
      example     = "";
      description = "Startup notice URL. Set to \"\" to disable the notice; null keeps upstream's.";
    };

    extraEnvironment = mkOption {
      type        = types.attrsOf types.str;
      default     = { };
      example     = { STORE_URL = "https://mirror.example/store"; };
      description = "Any other YeetPatch variables (MANIFEST_URL, STORE_URL, INSTALL_CATALOG_URL, NOTICE_ONCE, …).";
    };

    launcher = {
      enable = mkEnableOption "an \"Update VotV\" app-launcher entry (requires exePath)";

      terminalCommand = mkOption {
        type        = types.nullOr types.str;
        default     = null;
        example     = "wezterm start --";
        description = ''
          Command prefix that opens a terminal and runs the rest of the line.
          null marks the entry Terminal=true and leaves picking a terminal to
          your launcher, which not every launcher does well.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.launcher.enable -> cfg.exePath != null;
      message   = "programs.yeetpatch.launcher needs programs.yeetpatch.exePath, since `yeetpatch update` must know where VotV.exe is.";
    }];

    environment.systemPackages = [ configured ] ++ optional cfg.launcher.enable launcherEntry;
  };
}