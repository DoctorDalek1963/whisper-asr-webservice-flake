{
  fetchFromGitHub,
  dockerTools,
  buildEnv,
  python3,
  poetry,
  cudaPackages,
  jellyfin-ffmpeg,
}: let
  version = "1.8.2";

  python = python3.withPackages (p: [p.poetry-core]);

  src = fetchFromGitHub {
    owner = "ahmetoner";
    repo = "whisper-asr-webservice";
    tag = "v${version}";
    hash = "sha256-w2NixVPwPplo2r4QeY+5H1M8oBHKhwhFuQ05nh+sDa4=";
  };

  swagger-ui = fetchFromGitHub {
    owner = "swagger-api";
    repo = "swagger-ui";
    tag = "v5.21.0";
    hash = "sha256-acm/YpX+l9LTvFP4hsDoqHCAeTzvzAcpfvrK8vPPWkk=";
  };
in
  dockerTools.buildImage {
    name = "whisper-asr-webservice";
    tag = version;

    fromImage = dockerTools.pullImage {
      imageName = "nvidia/cuda";
      finalImageTag = "12.8.1-base-ubuntu22.04";
      imageDigest = "sha256:001469ea0f3dec85a1ca929aeea3b58ae369d4c11228b10aec1f642bb6ca7a6f";
      sha256 = "1kj1fljjl804x9fhmziymgsk665yi0afy3kvvravz4g2d896ilj9";
    };

    copyToRoot = buildEnv {
      name = "image-root";
      paths = [python poetry cudaPackages.cudnn jellyfin-ffmpeg];
      pathsToLink = "/bin";
    };

    runAsRoot = ''
      mkdir app
      cd app

      cp ${src}/poetry.lock ${src}/pyproject.toml ./
      poetry config virtualenvs.in-project true
      poetry install --no-root

      cp ${src} .
      mkdir swagger-ui-assets
      cp ${swagger-ui}/dist/swagger-ui.css swagger-ui-assets/
      cp ${swagger-ui}/dist/swagger-ui-bundle.js swagger-ui-assets/

      poetry install
      $POETRY_VENV/bin/pip install torch==2.6.0+cu126 torchaudio==2.6.0+cu126 --index-url https://download.pytorch.org/whl/cu126
    '';

    config = {
      Env = rec {
        POETRY_VENV = "/app/.venv";
        PATH = "/bin:${POETRY_VENV}/bin";
      };

      WorkingDir = "/app";
      Expose = 9000;

      Cmd = ["whisper-asr-webservice"];
    };
  }
