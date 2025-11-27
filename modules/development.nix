# Development tools configuration module
{ config, pkgs, lib, ... }: {
  # Development packages
  environment.systemPackages = with pkgs; [
    # Editors and IDEs
    vscode
    neovim
    jetbrains.idea-community

    # Version control
    git
    git-lfs
    gh

    # Languages and runtimes
    python3
    python3Packages.pip
    python3Packages.virtualenv
    nodejs
    nodePackages.npm
    go
    rustup
    jdk17

    # Build tools
    gcc
    gnumake
    cmake
    ninja
    meson

    # Containers and virtualization
    docker
    docker-compose
    podman

    # Database tools
    postgresql
    sqlite
    dbeaver

    # API and network tools
    curl
    wget
    httpie
    postman

    # Utilities
    jq
    yq
    ripgrep
    fd
    bat
    eza
    fzf
    direnv
    shellcheck
  ];

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable Podman
  virtualisation.podman.enable = true;

  # Direnv integration
  programs.direnv.enable = true;
}
