{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  awww,
  matugen,
  imagemagick,
  cava,
  bash,
  python3,
  coreutils,
  findutils,
  gnugrep,
}:

stdenvNoCC.mkDerivation {
  pname = "flui";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let
        base = baseNameOf path;
      in
        !(lib.hasPrefix "." base && base != ".config")
        && base != "flake.nix"
        && base != "flake.lock"
        && base != "package.nix"
        && base != "result";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/flui" "$out/bin"
    cp -r * "$out/share/flui/"

    # Wrapper script that sets up runtime PATH dependencies
    makeWrapper "${quickshell}/bin/quickshell" "$out/bin/flui" \
      --add-flags "-c $out/share/flui" \
      --prefix PATH : ${lib.makeBinPath [
        quickshell
        awww
        matugen
        imagemagick
        cava
        bash
        python3
        coreutils
        findutils
        gnugrep
      ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Fluid, minimalist Dynamic Island desktop shell built with Quickshell";
    homepage = "https://github.com/ElhamSadiqi/Luci";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "flui";
  };
}
