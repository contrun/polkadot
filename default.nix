{ pkgsPath ? <nixpkgs>, crossSystem ? null }:

let
  mozOverlay = import (builtins.fetchTarball
  "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz");
  pkgs = import pkgsPath {
    overlays = [ mozOverlay ];
    inherit crossSystem;
  };
  targets = [ pkgs.stdenv.targetPlatform.config "wasm32-unknown-unknown" ];

in with pkgs;

stdenv.mkDerivation {
  name = "polkadot";

  # build time dependencies targeting the build platform
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  HOST_CC = "cc";

  # build time dependencies targeting the host platform
  nativeBuildInputs = [
    (buildPackages.buildPackages.latest.rustChannels.nightly.rust.override {
      inherit targets;
    })
    buildPackages.buildPackages.rustfmt
    pkgs.llvmPackages.libclang
    pkgs.wasm-gc
  ];
  CARGO_BUILD_TARGET = [ pkgs.stdenv.targetPlatform.config ];

  # run time dependencies
  LIBCLANG_PATH = "${llvmPackages.libclang}/lib";
}
