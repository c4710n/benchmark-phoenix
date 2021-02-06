{ pkgs ? import <nixpkgs> { }, ... }:

let releaseName = "hello";
in pkgs.stdenv.mkDerivation rec {
  name = "hello";
  src = ./.;
  buildInputs = with pkgs; [ beam.packages.erlangR23.elixir_1_11 git ];

  phases = "unpackPhase buildPhase installPhase";

  buildPhase = ''
    export HOME=$PWD
    export LANG=en_US.UTF-8
    export MIX_ENV=prod

    mix local.hex --force
    mix local.rebar --force

    mix deps.get --only prod
    mix compile

    mix phx.digest

    mix release
  '';

  installPhase = ''
    mkdir -p $out
    cp -rf _build/prod/rel/${releaseName}/* $out/
  '';

  meta = {
    systemdExecStart = "bin/${releaseName} start";
    systemdExecStop = "bin/${releaseName} stop";
  };
}
