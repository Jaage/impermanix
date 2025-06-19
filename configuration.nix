{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_14;
  # boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # Flakes
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;

  # Impermanence
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.rollback = {
    description = "Rollback ZFS datasets to a blank snapshot taken immediately after disko formatting.";
    wantedBy = [
      "initrd.target"
    ];
    after = [
      "zfs-import-zroot.service"
    ];
    before = [
      "sysroot.mount"
    ];
    path = with pkgs; [
      zfs
    ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      zfs rollback -r zroot/root@blank && echo "blank rollback complete" | tee /dev/kmsg
    '';
  };
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log/journal/df374d06639f492eb6ab076160488b26"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
  environment.etc = {
    group.source = "/persist/etc/group";
    gshadow.source = "/persist/etc/gshadow";
    passwd.source = "/persist/etc/passwd";
    shadow.source = "/persist/etc/shadow";
    subgid.source = "/persist/etc/subgid";
    subuid.source = "/persist/etc/subuid";
    "zfs/zpool.cache".source = "/persist/etc/zfs/zpool.cache";
  };
  security.sudo.extraConfig = ''
    # Don't display sudo lecture after rollback on reboot
    Defaults lecture = never
  '';

  networking.hostName = "nixos";
  networking.hostId = "146beaaf";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
  };

  hardware.graphics.enable = true;
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
  services.xserver.videoDrivers = [ "nvidia" ]; # enable nvidia-smi

  # Logitech
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "";

  # Security
  security = {
    rtkit.enable = true;
  };

  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.jjh = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Create passwd with: sudo mkpasswd -m sha-512 "passwd_here" > /mnt/persist/passwords/user during installation
    hashedPasswordFile = "/persist/passwords/jjh";
  };

  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    # Browser
    firefox

    # CLI
    eza
    fastfetch
    fzf
    ripgrep
    starship
    stow
    zoxide

    # Formatters
    nixfmt-rfc-style

    # Programs
    discord
    gnome-keyring
    inputs.nixvim.packages.x86_64-linux.default
    solaar
    tofi
    vim
    walker

    # Terminal
    ghostty
  ];

  programs.git = {
    enable = true;
    config = {
      credential.helper = "libsecret";
    };
    package = pkgs.git.override { withLibsecret = true; };
  };
  programs.seahorse.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.extraUsers.jjh.shell = pkgs.zsh;

  system.stateVersion = "25.11";
}
