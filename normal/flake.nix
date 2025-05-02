{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    whisper-asr-webservice = pkgs.callPackage ./package.nix {};
  in {
    packages.${system}.default = whisper-asr-webservice;

    apps.${system}.default = {
      type = "app";
      program = "${whisper-asr-webservice}/bin/whisper-asr-webservice";
    };
  };
}
