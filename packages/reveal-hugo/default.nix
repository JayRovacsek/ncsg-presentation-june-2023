{ lib, fetchFromGitHub, buildGoModule }:
let
  pname = "reveal-hugo";
  version = "0.0.1";

  meta = with lib; {
    homepage = "https://github.com/dzello/reveal-hugo";
    description =
      "A Hugo theme for Reveal.js that makes authoring and customization a breeze. With it, you can turn any properly-formatted Hugo content into a HTML presentation.";
    license = licenses.mit;
  };

  src = fetchFromGitHub {
    owner = "dzello";
    repo = "reveal-hugo";
    rev = "b5fd252eab494a29ba55b799fb2ad787f3b93aae";
    sha256 = "sha256-stX/gi0c0Nt+wDPQCoJdR9ki5QuYNgmkeHnW9Ik1Q/4=";
  };

  vendorHash = null;

in buildGoModule { inherit pname version src meta vendorHash; }
