{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
    # poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;};

    whisper-asr-webservice = pkgs.callPackage ./package.nix {
      inherit poetry2nix;
    };
  in {
    packages.${system}.default = whisper-asr-webservice;

    apps.${system}.default = {
      type = "app";
      program = "${whisper-asr-webservice}/bin/whisper-asr-webservice";
    };
  };
}
