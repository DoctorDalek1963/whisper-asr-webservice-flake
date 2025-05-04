{whisper-asr-webservice}: {
  lib,
  config,
  ...
}: let
  cfg = config.services.whisper-asr;

  inherit (lib) mkOption types;
in {
  options.services.whisper-asr = {
    enable = lib.mkEnableOption "Whisper ASR";

    package = mkOption {
      type = types.package;
      default = whisper-asr-webservice;
      description = "The whisper-asr-webservice package to use.";
    };

    dataDir = mkOption {
      type = types.nonEmptyStr;
      default = "/var/lib/whisper-asr";
      description = "The directory where Whisper ASR keeps its files.";
    };

    user = mkOption {
      type = types.nonEmptyStr;
      default = "whisper-asr";
      description = "User account under which the Whisper ASR service runs.";
    };

    group = mkOption {
      type = types.nonEmptyStr;
      default = "whisper-asr";
      description = "Group under which the Whisper ASR runs.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the port for Whisper ASR in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.whisper-asr = {
        description = "Whisper ASR";
        script = "${cfg.package}/bin/whisper-asr-webservice";

        requires = ["network-online.target"];
        after = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;

          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      tmpfiles.settings.whisperAsr."${cfg.dataDir}".d = {
        mode = "750";
        inherit (cfg) user group;
      };
    };

    users.users.whisper-asr = lib.mkIf (cfg.user == "whisper-asr") {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.dataDir;
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [9000];
    };
  };
}
