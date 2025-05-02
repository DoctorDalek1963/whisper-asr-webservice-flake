{
  lib,
  fetchFromGitHub,
  poetry2nix,
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

    # overrides = poetry2nix.overrides.withDefaults (final: prev: {
    #   fastapi-cli = prev.fastapi-cli.overridePythonAttrs {
    #     dependencies = with final; [
    #       typer
    #       uvicorn
    #       uvicorn.optional-dependencies.standard
    #     ];
    #   };
    # });

    meta = {
      description = "OpenAI Whisper ASR Webservice API";
      homepage = "https://ahmetoner.com/whisper-asr-webservice/";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
