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
          sqlx-cli
          rustPlatform
        ];
      };
    });
}
