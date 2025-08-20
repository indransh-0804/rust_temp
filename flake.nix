{
  description = "Rust Development Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [(import inputs.rust-overlay)];
        };

        rustInfo = let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = ["rust-src" "clippy" "rustfmt"];
            targets = ["x86_64-unknown-linux-musl"];
          };
        in {
          name = "rust-stable-default";
          target = "x86_64-unknown-linux-musl";
          path = "${rustToolchain}/lib/rustlib/src/rust/library";
          nativeBuildInputs = with pkgs; [
            rustToolchain
            pkg-config
            rust-analyzer
          ];
          buildInputs = with pkgs; [
            eza
            just
            openssl
            lld
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = rustInfo.name;
          RUST_SRC_PATH = rustInfo.path;
          buildInputs = rustInfo.buildInputs;
          nativeBuildInputs = rustInfo.nativeBuildInputs;
          shellHook = ''
            export RUST_BACKTRACE=1
            export CARGO_BUILD_TARGET="${rustInfo.target}"
            export CARGO_TARGET_DIR=$PWD/target/${rustInfo.target}
            export CARGO_HOME=$PWD/.cargo

            alias ls='eza -a --icons'
            alias lt='eza -T --icons --git-ignore'

            echo "🦀 building development environment for ${rustInfo.name} ..."
          '';
        };
      };
    };
}
