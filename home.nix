{ config, pkgs, ... }:

{
  home.username = "di";
  home.homeDirectory = "/Users/di";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.zsh.enable = true;

  home.packages = with pkgs; [
    git
    neovim
    ripgrep
    fd
  ];

  programs.git = {
    enable = true;
    userName = "Denys Yahofarov";
    userEmail = "denyago@gmail.com";
  };
}

