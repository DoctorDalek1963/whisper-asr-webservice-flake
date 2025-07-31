{ whisper-asr-webservice }:
{
  lib,
  config,
  ...
}:
let
  cfg = config.services.whisper-asr;

  inherit (lib) mkOption types;
in
{
  options.services.whisper-asr = {
    enable = lib.mkEnableOption "Whisper ASR";

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to automatically start the systemd service for Whisper ASR.

        By default, the AI model is loaded in VRAM on the GPU at all times
        while the service is running. On more limited systems, the
        recommendation is to set `settings.modelIdleTimeout` to unload the
        model automatically, but you might want to only run Whisper on demand.
      '';
    };

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

    settings = {
      asrEngine = mkOption {
        type = types.enum [
          "openai_whisper"
          "faster_whisper"
          "whisperx"
        ];
        default = "openai_whisper";
        description = "Engine selection.";
      };

      asrModel = mkOption {
        type = types.nonEmptyStr;
        default = "base";
        description = "See https://ahmetoner.com/whisper-asr-webservice/environmental-variables/#configuring-the-model";
      };

      asrModelPath = mkOption {
        type = types.nullOr types.nonEmptyStr;
        default = null;
        description = "Custom path to store/load models.";
      };

      asrDevice = mkOption {
        type = types.nullOr (
          types.enum [
            "cuda"
            "cpu"
          ]
        );
        default = null;
        description = "The device to use. Set to `null` to use the default of using cuda if it's available.";
      };

      asrQuantization = mkOption {
        type = types.nullOr (
          types.enum [
            "float32"
            "float16"
            "int8"
          ]
        );
        default = null;
        description = "The precision for model weights. Set to `null` to use the defaults of float32 on CUDA and int8 on CPU.";
      };

      modelIdleTimeout = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = ''
          Load the AI model into VRAM on demand and unload it after this many
          seconds of inactivity. Set to `null` to keep the model loaded constantly.
        '';
      };

      sampleRate = mkOption {
        type = types.ints.positive;
        default = 16000;
        description = "Sample rate for audio input.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.whisper-asr = {
        description = "Whisper ASR";
        script = "${cfg.package}/bin/whisper-asr-webservice";

        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];

        wantedBy = lib.mkIf cfg.autoStart [ "multi-user.target" ];

        environment =
          let
            ifNotNull = x: lib.mkIf (x != null) x;
          in
          {
            ASR_ENGINE = cfg.settings.asrEngine;

            ASR_MODEL = cfg.settings.asrModel;

            ASR_MODEL_PATH = ifNotNull cfg.settings.asrModelPath;

            ASR_DEVICE = ifNotNull cfg.settings.asrDevice;

            ASR_QUANTIZATION = ifNotNull cfg.settings.asrQuantization;

            MODEL_IDLE_TIMEOUT =
              if (cfg.settings.modelIdleTimeout == null) then "0" else toString cfg.settings.modelIdleTimeout;

            SAMPLE_RATE = toString cfg.settings.sampleRate;
          };

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;

          WorkingDirectory = cfg.dataDir;

          Restart = "on-failure";
          RestartSec = 10;

          # Hardening
          IPAddressAllow = "127.0.0.1";
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_NETLINK"
            "AF_INET"
            "AF_INET6"
          ];

          LockPersonality = true;
          NoNewPrivileges = true;

          PrivateTmp = true;
          PrivateUsers = "self";

          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          ReadWritePaths = [ cfg.dataDir ];

          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          MemoryDenyWriteExecute = false;

          AmbientCapabilities = "";
          CapabilityBoundingSet = "";
          SystemCallFilter = [ "@system-service" ];
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
      allowedTCPPorts = [ 9000 ];
    };
  };
}
