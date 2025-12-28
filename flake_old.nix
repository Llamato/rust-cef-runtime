{
  description = "NixOS unstable - dev shell (fixed)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Test: check tarball structure first
        cef-tarball = pkgs.fetchurl {
          url = "https://cef-builds.spotifycdn.com/cef_binary_143.0.13+g30cb3bd+chromium-143.0.7499.170_linux64.tar.bz2";
          sha256 = "sha256-Bd2xd5iHH1QAGxeD2vTZGkeuM/eNIEqzbcEDS9dxOTw=";
        };
        
        cef-binary-143 = pkgs.runCommand "cef-binary-143" {} ''
          # Extract and check structure
          mkdir -p $out
          tar -xf ${cef-tarball} -C $out
          
          # Check if there's a single top-level directory
          cd $out
          if [ $(ls -1 | wc -l) -eq 1 ]; then
            dir=$(ls -1)
            echo "Single directory: $dir"
            # Move contents up
            mv "$dir"/* .
            rm -R "$dir"
          fi
          
          echo "Final structure:"
          ls -la
        '';
        
        runtimeDeps = with pkgs; [
          openssl
          dbus
          at-spi2-core
          glib
          libGL
          libxkbcommon
          wayland
          xorg.libX11
          xorg.libXcomposite
          xorg.libXcursor
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXi
          xorg.libXrandr
          xorg.libXrender
          xorg.libXScrnSaver
          xorg.libXtst
          xorg.libxcb
          gtk3
          nss
          nspr
          pango
          cairo
          alsa-lib
          at-spi2-atk
          atk
          cups
          expat
          fontconfig
          gdk-pixbuf
          libva
          libgbm
          libvdpau
          systemd
        ];
        
        buildDeps = with pkgs; [ rustc cargo pkg-config ];
      in {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "rust-cef-runtime";
          version = "0.1.0";
          src = ./.;
          buildInputs = runtimeDeps ++ [ cef-binary-143 ];
          nativeBuildInputs = buildDeps ++ [ pkgs.pkg-config ];
          
          cargoLock.lockFile = ./Cargo.lock;
          
          CEF_PATH = "${cef-binary-143}";
          CEF_BINARY_DIR = "${cef-binary-143}";
          
          preBuild = ''
            export CEF_PATH="${cef-binary-143}"
            export CEF_BINARY_DIR="$CEF_PATH"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (runtimeDeps ++ [ cef-binary-143 ])}:$CEF_PATH/Release"
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = buildDeps ++ runtimeDeps ++ [ cef-binary-143 ];
          
          CEF_PATH = "${cef-binary-143}";
          CEF_BINARY_DIR = "${cef-binary-143}";
          
          shellHook = ''
            export PKG_CONFIG_PATH="${
              pkgs.lib.makeSearchPath "lib/pkgconfig" (runtimeDeps ++ [ cef-binary-143 ])
            }"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (runtimeDeps ++ [ cef-binary-143 ])}"
            
            export CEF_PATH="${cef-binary-143}"
            export CEF_BINARY_DIR="$CEF_PATH"
            export PATH="$HOME/.cargo/bin:$PATH"
            
            echo "Using CEF 143.0.13"
            echo "rust-cef-runtime dev shell ready"
          '';
        };
      });
}