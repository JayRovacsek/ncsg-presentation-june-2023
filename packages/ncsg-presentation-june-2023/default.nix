{ self, reveal-hugo, lib, hugo, stdenv, go, git, ... }:
let
  name = "ncsg-presentation-june-2023";
  src = self;
  meta = with lib; {
    homepage = "https://github.com/JayRovacsek/ncsg-presentation-june-2023";
    description = "";
    license = licenses.mit;
  };

  nativeBuildInputs = [ go git ];

  propagatedBuildInputs = [ reveal-hugo ];

  buildPhase = ''
    mkdir -p $out/share
    ${hugo}/bin/hugo -s $src
    cp -r ./public $out/share
  '';

  phases = [ "buildPhase" ];

in stdenv.mkDerivation {
  inherit src meta buildPhase name phases nativeBuildInputs git
    propagatedBuildInputs;
}
