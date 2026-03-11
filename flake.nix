{
  description = "openLCA - Life Cycle Assessment software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        openlca = pkgs.stdenv.mkDerivation rec {
          pname = "openlca";
          version = "2.6.1";

          src = pkgs.fetchurl {
            url = "https://share.greendelta.com/index.php/s/p6HGtyfVjKaHZN3/download";
            sha256 = "0ai0gw8s64nhf41d9966cd4fhmcxvv3hxsmb49b6asrhfzj0zvsj";
            name = "openLCA_mkl_Linux_x64_${version}.tar.gz";
          };

          # tar.gz extracts into openLCA/ subdirectory
          sourceRoot = "openLCA";

          nativeBuildInputs = with pkgs; [
            patchelf
            makeWrapper
            autoPatchelfHook
          ];

          buildInputs = with pkgs; [
            # GUI
            gtk3
            gtk4
            glib
            gsettings-desktop-schemas
            libX11
            libXtst
            libXrender
            libXi
            freetype
            fontconfig
            zlib
            libGL
            cairo
            pango
            harfbuzz
            atk
            gdk-pixbuf

            # Audio (JRE libjsound.so)
            alsa-lib

            # OpenCL
            ocl-icd

            # Intel TBB (for libmkl_tbb_thread)
            onetbb

            # Intel MKL runtime libs
            mkl
          ];

          autoPatchelfIgnoreMissingDeps = [
            "libc.so.8"          
            "libsycl.so.6"       
            "libOpenCL.so.1"     
            "libze_loader.so.1"  
            "libimf.so"         
            "libsvml.so"         
            "libirng.so"         
            "libintlc.so.5"     
          ];

          dontBuild = true;
          dontConfigure = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/opt/openlca
            cp -r . $out/opt/openlca/
            chmod +x $out/opt/openlca/openLCA

            mkdir -p $out/bin
            makeWrapper $out/opt/openlca/openLCA $out/bin/openlca \
              --chdir "$out/opt/openlca" \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs} \
              --set GSETTINGS_SCHEMA_DIR "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas"

            mkdir -p $out/share/applications
            cat > $out/share/applications/openlca.desktop << EOF
            [Desktop Entry]
            Name=openLCA
            Comment=Life Cycle Assessment software
            Exec=$out/bin/openlca
            Terminal=false
            Type=Application
            Categories=Science;
            EOF

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A free, open source software for life cycle assessment";
            homepage = "https://www.openlca.org";
            license = licenses.mpl20;
            platforms = [ "x86_64-linux" ];
            mainProgram = "openlca";
          };
        };

      in {
        packages = {
          inherit openlca;
          default = openlca;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = openlca;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ openlca ];
        };
      }
    );
}
