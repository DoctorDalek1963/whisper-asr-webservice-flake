{
  fetchFromGitHub,
  python3Packages,
}: let
  version = "1.8.2";
in
  python3Packages.buildPythonApplication {
    name = "whisper-asr-webservice";
    inherit version;

    src = fetchFromGitHub {
      owner = "ahmetoner";
      repo = "whisper-asr-webservice";
      tag = "v${version}";
      hash = "sha256-w2NixVPwPplo2r4QeY+5H1M8oBHKhwhFuQ05nh+sDa4=";
    };

    pyproject = true;

    nativeBuildInputs = [python3Packages.poetry-core];

    dependencies = with python3Packages; [
      fastapi
      faster-whisper
      ffmpeg-python
      llvmlite
      numba # numbaWithCuda
      numpy_1
      openai-whisper
      python-multipart
      torch
      torchaudio
      tqdm
      uvicorn
      whisperx
    ];

    # This package wants numpy 1 despite some of its dependencies wanting numpy
    # 2, so we have to allow conflicts and relax the dependency even though
    # everything's fine
    catchConflicts = false;

    pythonRelaxDeps = [
      "numpy"
      "torch"
      "torchaudio"
    ];
  }
