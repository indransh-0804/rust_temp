{
  description = "Rust Development Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
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
        lib,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.rust-overlay.overlays.default];
        };
        rustInfo = let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = ["rust-src" "clippy" "rustfmt" "rust-analyzer"];
            targets = ["x86_64-unknown-linux-musl"];
          };
        in {
          name = "rust-stable-default";
          target = "x86_64-unknown-linux-musl";
          path = "${rustToolchain}/lib/rustlib/src/rust/library";
          nativeBuildInputs = with pkgs; [
            rustToolchain
            pkg-config
          ];
          buildInputs = with pkgs; [
            eza
            just
            openssl
            sqlite
            zlib
            libiconv
            lld
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = rustInfo.name;

          buildInputs = rustInfo.buildInputs;
          nativeBuildInputs = rustInfo.nativeBuildInputs;

          env = {
            RUST_BACKTRACE = "1";
            RUST_SRC_PATH = rustInfo.path;
            RUSTFLAGS = "-C link-arg=-fuse-ld=lld";
            CARGO_BUILD_TARGET = rustInfo.target;
          };

          shellHook = ''
            export CARGO_TARGET_DIR=$PWD/target
            export CARGO_HOME=$PWD/.cargo
            alias ls='eza -a --icons'
            alias lt='eza -T --icons --git-ignore'
            echo "🦀 ${rustInfo.name} environment on ${system}!"
          '';
        };
      };

      flake.templates.default = {
        path = ./.;
        description = "Rust Project template with Nix DevShell";
      };
    };
}
