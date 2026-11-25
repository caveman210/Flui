{
  lib,
  rustPlatform,
  makeWrapper,
  quickshell,
  awww,
  matugen,
  imagemagick,
  cava,
  bash,
  coreutils,
  findutils,
  gnugrep,
}:

rustPlatform.buildRustPackage {
  pname = "flui";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: type:
      let
        base = baseNameOf path;
      in
      !(lib.hasPrefix "." base && base != ".config")
      && base != "flake.nix"
      && base != "flake.lock"
      && base != "package.nix"
      && base != "result";
  };

  sourceRoot = "source/helpers";
  cargoLock.lockFile = ./helpers/Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    mkdir -p "$out/share/flui" "$out/bin"
    cp -r ../* "$out/share/flui/"
    rm -rf "$out/share/flui/helpers/target"

    # Move compiled Rust helper binary into package bin
    # (Cargo already placed flui-helper in $out/bin/)

    # Create flui shell launcher
    cat <<'EOF' > "$out/bin/flui"
    #!/usr/bin/env bash
    set -e

    CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_DIR/settings.json" ]; then
      if [ -f "$CONFIG_DIR/settings.json.example" ]; then
        cp "$CONFIG_DIR/settings.json.example" "$CONFIG_DIR/settings.json"
      elif [ -f "@FLUI_SHARE@/settings.json.example" ]; then
        cp "@FLUI_SHARE@/settings.json.example" "$CONFIG_DIR/settings.json"
      fi
    fi

    mkdir -p "$CONFIG_DIR/styles/themes/matugen"
    if [ ! -f "$CONFIG_DIR/styles/themes/matugen/Theme.qml" ]; then
      if [ -f "$CONFIG_DIR/styles/themes/matugen/Theme.qml.example" ]; then
        cp "$CONFIG_DIR/styles/themes/matugen/Theme.qml.example" "$CONFIG_DIR/styles/themes/matugen/Theme.qml"
      elif [ -f "@FLUI_SHARE@/styles/themes/matugen/Theme.qml.example" ]; then
        cp "@FLUI_SHARE@/styles/themes/matugen/Theme.qml.example" "$CONFIG_DIR/styles/themes/matugen/Theme.qml"
      fi
    fi

    if [ "$1" = "ipc" ]; then
      shift
      exec quickshell ipc call flui "$@"
    fi

    exec quickshell -c "@FLUI_SHARE@" "$@"
    EOF

    substituteInPlace "$out/bin/flui" --replace "@FLUI_SHARE@" "$out/share/flui"
    chmod +x "$out/bin/flui"

    wrapProgram "$out/bin/flui" \
      --prefix PATH : ${
        lib.makeBinPath [
          quickshell
          awww
          matugen
          imagemagick
          cava
          bash
          coreutils
          findutils
          gnugrep
        ]
      }:"$out/bin"
  '';

  meta = with lib; {
    description = "Fluid, minimalist Dynamic Island desktop shell built with Quickshell";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "flui";
  };
}
