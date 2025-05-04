{
  lib,
  fetchFromGitHub,
  python312,
  poetry2nix,
  llvmPackages_15,
  rdma-core,
  ninja,
}: let
  version = "1.8.2";
in
  poetry2nix.mkPoetryApplication {
    pname = "whisper-asr-webservice";
    inherit version;

    projectDir = fetchFromGitHub {
      owner = "ahmetoner";
      repo = "whisper-asr-webservice";
      tag = "v${version}";
      hash = "sha256-w2NixVPwPplo2r4QeY+5H1M8oBHKhwhFuQ05nh+sDa4=";
    };

    python = python312;

    poetrylock = ./poetry.lock;

    overrides = poetry2nix.overrides.withDefaults (final: prev: {
      inherit
        (python312.pkgs)
        hyperpyyaml
        pyannote-audio
        pyannote-core
        pyannote-metrics
        pyannote-pipeline
        safetensors
        tiktoken
        tokenizers
        typing-inspection
        ;

      numpy = python312.pkgs.numpy_1;

      # FIXME: Some files don't exist when trying to clean after pip build
      llvmlite = let
        inherit (llvmPackages_15) llvm;
      in
        prev.llvmlite.overridePythonAttrs (old: {
          inherit llvm;
          nativeBuildInputs = old.nativeBuildInputs or [] ++ [final.llvmlite.llvm];

          # Set directory containing llvm-config binary
          preConfigure = ''
            export LLVM_CONFIG=${llvm.dev}/bin/llvm-config
          '';

          passthru = old.passthru // {inherit llvm;};
        });

      nvidia-cufile-cu12 = prev.nvidia-cufile-cu12.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [rdma-core];
      });

      uvicorn = prev.uvicorn.overridePythonAttrs {
        optional-dependencies.standard = with final; [
          httptools
          python-dotenv
          pyyaml
          uvloop
          watchfiles
          websockets
        ];
      };

      # FIXME: Wants ninja but has no build.ninja file
      whisperx = prev.whisperx.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ninja];
      });

      fastapi = prev.fastapi.overridePythonAttrs {catchConflicts = false;};
      faster-whisper = prev.faster-whisper.overridePythonAttrs {catchConflicts = false;};
      pydantic = prev.pydantic.overridePythonAttrs {catchConflicts = false;};
      pyannote-database = prev.pyannote-database.overridePythonAttrs {catchConflicts = false;};
      speechbrain = prev.speechbrain.overridePythonAttrs {catchConflicts = false;};
      transformers = prev.transformers.overridePythonAttrs {catchConflicts = false;};
    });

    meta = {
      description = "OpenAI Whisper ASR Webservice API";
      homepage = "https://ahmetoner.com/whisper-asr-webservice/";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
