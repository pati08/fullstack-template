{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    , rust-overlay
    , crane
    ,
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
          (self: super: {
            dioxus-cli =
              super.callPackage
                ({ lib
                 , stdenv
                 , fetchCrate
                 , rustPlatform
                 , pkg-config
                 , rustfmt
                 , cacert
                 , openssl
                 , nix-update-script
                 , testers
                 , dioxus-cli
                 ,
                 }:
                  rustPlatform.buildRustPackage
                    rec {
                      pname = "dioxus-cli";
                      version = "0.7.1";

                      src = fetchCrate {
                        inherit pname version;
                        hash = "sha256-tPymoJJvz64G8QObLkiVhnW0pBV/ABskMdq7g7o9f1A=";
                      };

                      cargoHash = "sha256-mgscu6mJWinB8WXLnLNq/JQnRpHRJKMQXnMwECz1vwc=";

                      buildFeatures = [
                        "no-downloads"
                      ];

                      nativeBuildInputs = with pkgs; [
                        pkg-config
                        cacert
                      ];

                      buildInputs = with pkgs; [ openssl ];

                      OPENSSL_NO_VENDOR = 1;

                      nativeCheckInputs = with pkgs; [ rustfmt ];

                      checkFlags = [
                        # requires network access
                        "--skip=serve::proxy::test"
                        "--skip=wasm_bindgen::test"

                        # seems broken
                        "--skip=test_harnesses::run_harness"
                      ];

                      passthru = {
                        updateScript = nix-update-script { };
                        tests.version = testers.testVersion { package = dioxus-cli; };
                      };

                      meta = with lib; {
                        homepage = "https://dioxuslabs.com";
                        description = "CLI tool for developing, testing, and publishing Dioxus apps";
                        changelog = "https://github.com/DioxusLabs/dioxus/releases";
                        license = with licenses; [
                          mit
                          asl20
                        ];
                        maintainers = with maintainers; [
                          xanderio
                          cathalmullan
                        ];
                        mainProgram = "dx";
                      };
                    })
                { };
          })
          (self: super: {
            wasm-bindgen-cli =
              super.callPackage
                ({ buildWasmBindgenCli
                 , fetchCrate
                 , rustPlatform
                 , lib
                 ,
                 }:
                  buildWasmBindgenCli rec {
                    src = fetchCrate {
                      pname = "wasm-bindgen-cli";
                      version = "0.2.105";
                      hash = "sha256-zLPFFgnqAWq5R2KkaTGAYqVQswfBEYm9x3OPjx8DJRY=";
                    };
                    cargoDeps =
                      rustPlatform.fetchCargoVendor
                        {
                          inherit src;
                          inherit (src) pname version;
                          hash = "sha256-a2X9bzwnMWNt0fTf30qAiJ4noal/ET1jEtf5fBFj5OU=";
                        };
                  })
                { };
          })
        ];
      };
      rustPlatform = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" "rustfmt" ];
        targets = [ "x86_64-unknown-linux-gnu" "wasm32-unknown-unknown" ];
      };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          wasm-bindgen-cli
          dioxus-cli
          tailwindcss
          tailwindcss-language-server
          sqlx-cli
          rustPlatform
          binaryen
        ];
      };
    });
}
