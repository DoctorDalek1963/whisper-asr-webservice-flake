{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;};

    whisper-asr-webservice-unwrapped = pkgs.callPackage ./package.nix {
      inherit poetry2nix;
    };

    whisper-asr-webservice = let
      cudaLibs = with pkgs.cudaPackages; [
        cusparselt
        libcufile
      ];
    in
      pkgs.stdenvNoCC.mkDerivation {
        inherit (whisper-asr-webservice-unwrapped) pname version;

        dontUnpack = true;
        nativeBuildInputs = with pkgs; [makeWrapper];

        buildPhase = ''
          makeWrapper ${whisper-asr-webservice-unwrapped}/bin/whisper-asr-webservice whisper-asr-webservice \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath cudaLibs}" \
            --prefix PATH : "${pkgs.jellyfin-ffmpeg}/bin"
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp whisper-asr-webservice $out/bin/
        '';
      };
  in {
    packages.${system} = {
      default = whisper-asr-webservice;

      inherit whisper-asr-webservice-unwrapped whisper-asr-webservice;
    };

    apps.${system}.default = {
      type = "app";
      program = "${whisper-asr-webservice}/bin/whisper-asr-webservice";
    };

    nixosModules.default = import ./module.nix {inherit whisper-asr-webservice;};
  };
}
