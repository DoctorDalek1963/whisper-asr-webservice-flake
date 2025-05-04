{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;};

    whisper-asr-webservice-unwrapped = pkgs.callPackage ./package.nix {
      inherit poetry2nix;
    };

    # TODO: Wrap this with CUDA libs and ffmpeg (and swagger-ui?)
    whisper-asr-webservice = whisper-asr-webservice-unwrapped;
  in {
    packages.${system} = {
      default = whisper-asr-webservice;

      inherit whisper-asr-webservice-unwrapped whisper-asr-webservice;
    };

    apps.${system}.default = {
      type = "app";
      program = "${whisper-asr-webservice}/bin/whisper-asr-webservice";
    };
  };
}
