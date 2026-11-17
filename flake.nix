{
  description = "Resume builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fonts = {
      url = path:/home/rickyrnt/nixos/dotfiles/fonts;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    inputs.flake-utils.lib.eachDefaultSystem(system:
      let 
        pkgs = (import inputs.nixpkgs) { inherit system; };
        bahnschrift = inputs.fonts.packages.${system}.bahnschrift;
        tex = pkgs.texliveFull;
        maketex = source: hides: pkgs.stdenvNoCC.mkDerivation rec {
          name = "Eric-Yarnot-Resume";
          src = self;
          buildInputs = [ pkgs.coreutils bahnschrift tex ];
          phases = ["unpackPhase" "buildPhase" "installPhase"];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath buildInputs}";
            mkdir -p .cache/texmf-var
            substitute ${source}.tex in.tex ${builtins.concatStringsSep " " (map (x: "--replace-quiet %%" + x + "-%% \\\\begin\\{comment\\} --replace-quiet %%-"+ x + "%% \\\\end\\{comment\\}") hides)}
            env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
                OSFONTDIR=${bahnschrift}/share/fonts \
              xelatex -interaction=nonstopmode \
              in.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp in.pdf $out/${source}.pdf
          '';
        };
      in {
        packages = rec {
          physics = maketex "resume" ["ENGINEERING"];
          physcv = maketex "cv" ["PROJECTS" "NPROJECTS"];
          default = physcv;
        };
      }
    );
}
