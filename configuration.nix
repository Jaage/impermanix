{
  inputs,
  config,
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
  boot.kernelPackages = pkgs.linuxPackages_latest;
  systemd.enableEmergencyMode = false;

  # Variables

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

  # Garbage collection
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    flake = "/etc/nixos";
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
      "/etc/zfs/zpool.cache"
    ];
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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
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
  # Wooting keyboard detection
  hardware.wooting.enable = true;

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

  users = {
    mutableUsers = false; # Needed for impermanece.
    users = {
      jjh = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        # Create passwd with: sudo mkpasswd -m sha-512 "passwd_here" > /mnt/persist/passwords/user during installation
        hashedPasswordFile = "/persist/passwords/jjh";
      };
    };
  };

  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    # Browser
    firefox

    # CLI
    eza
    fastfetch
    fd
    fio
    fzf
    jq
    p7zip
    pigz
    ripgrep
    starship
    stow
    unzip
    wl-clipboard
    zoxide

    # Formatters
    nixfmt-rfc-style

    # Programs
    bolt-launcher
    discord
    gamescope-wsi # Needed for gamescope HDR
    inputs.nixvim.packages.x86_64-linux.default
    lutris
    solaar
    vim
    walker
    wootility
    wowup-cf

    # Terminal
    ghostty
  ];
  fonts.packages = with pkgs; [
    inputs.nix-fonts.defaultPackage.x86_64-linux
    nerd-fonts._0xproto
    terminus_font
  ];

  programs.git = {
    enable = true;
  };

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

  system.stateVersion = "25.11";
}
