{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    whisper-asr-webservice = import ./package.nix {
      inherit (pkgs) lib fetchFromGitHub;
      inherit (inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryApplication;
    };
  in {
    packages.${system}.default = whisper-asr-webservice;

    apps.${system}.default = {
      type = "app";
      program = "${whisper-asr-webservice}/bin/whisper-asr-webservice";
    };
  };
}
