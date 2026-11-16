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

    # Wrapper script: handles initial config setup, path resolution, and runtime PATH
    cat <<'EOF' > "$out/bin/flui"
    #!/usr/bin/env bash
    set -e

    CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
    mkdir -p "$CONFIG_DIR"

    # Initialize settings.json from template on first run if missing
    if [ ! -f "$CONFIG_DIR/settings.json" ]; then
      if [ -f "$CONFIG_DIR/settings.json.example" ]; then
        cp "$CONFIG_DIR/settings.json.example" "$CONFIG_DIR/settings.json"
      elif [ -f "@FLUI_SHARE@/settings.json.example" ]; then
        cp "@FLUI_SHARE@/settings.json.example" "$CONFIG_DIR/settings.json"
      fi
    fi

    # Convenient IPC subcommand routing
    if [ "$1" = "ipc" ]; then
      shift
      exec quickshell ipc call flui "$@"
    fi

    exec quickshell -c "@FLUI_SHARE@" "$@"
    EOF

    # Substitute @FLUI_SHARE@ with the store path
    substituteInPlace "$out/bin/flui" --replace "@FLUI_SHARE@" "$out/share/flui"
    chmod +x "$out/bin/flui"

    # Wrap the launcher with all runtime dependencies prepended to PATH
    wrapProgram "$out/bin/flui" \
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
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "flui";
  };
}
