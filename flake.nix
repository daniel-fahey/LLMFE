{
  description = "Developer shell flake. Nix for the system, uv for Python.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3016b4b15d13f3089db8a41ef937b13a9e33a8df"; # 2025-06-30
    # nixpkgs.url = "github:NixOS/nixpkgs/62e0f05ede1da0d54515d4ea8ce9c733f12d9f08"; # 2025-07-14
    agenix-shell.url = "github:aciceri/agenix-shell";
  };

  outputs =
    { self, nixpkgs, agenix-shell }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
        overlays = [
        #  (final: prev: {
        #    whisper-cpp = prev.whisper-cpp.overrideAttrs (oldAttrs: {
        #      version = "1.7.6"; # working see https://github.com/NixOS/nixpkgs/issues/409684
        #      src = prev.fetchFromGitHub {
        #        owner = "ggml-org";
        #        repo = "whisper.cpp";
        #        tag = "v1.7.6";
        #        hash = "sha256-dppBhiCS4C3ELw/Ckx5W0KOMUvOHUiisdZvkS7gkxj4=";
        #      };
        #    });
        #  })
        ];
      };



      cudaLibs = with pkgs; [
        cudaPackages.cudatoolkit
        cudaPackages.cudnn_8_9.lib
        cudaPackages.libcublas
        cudaPackages.libcurand
        cudaPackages.libcusparse
        cudaPackages.libcufft
        linuxPackages_latest.nvidiaPackages.latest
        glib
      ];

    in
    {
      formatter."${system}" = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      devShells.${system}.default = 
	let
	  lib = pkgs.lib;
          installationScript = agenix-shell.lib.installationScript pkgs.system {
            secrets = {
              openai-api-key.file = ./secrets/openai-api-key.age;
            };
          };
	in
	pkgs.mkShell {
        buildInputs =
          with pkgs;
          [
            ffmpeg
            python3
            uv
            python3Packages.huggingface-hub
          ]
          ++ cudaLibs;

        shellHook = ''
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath cudaLibs}:$LD_LIBRARY_PATH
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath ["/run/opengl-driver"] }:$LD_LIBRARY_PATH
          export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
          export CUDNN_HOME=${pkgs.cudaPackages.cudnn_8_9}
          export UV_PYTHON_DOWNLOADS=never # Prevent uv from downloading Python

	  # Load secrets using agenix-shell
	  source ${lib.getExe installationScript}
	  export OPENAI_API_KEY="$openai__api__key"
        '';
      };
    };
}
