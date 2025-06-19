{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_14;

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
#      "/etc/group"
      # "/etc/gshadow"
      "/etc/machine-id"
#      "/etc/passwd"
     # "/etc/shadow"
#      "/etc/subgid"
#      "/etc/subuid"
#      "/etc/zfs/zpool.cache"
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

  users.users.jjh = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Create passwd with: sudo mkpasswd -m sha-512 "passwd_here" > /mnt/persist/passwords/user during installation
    hashedPasswordFile = "/persist/passwords/jjh";
  };

  environment.systemPackages = with pkgs; [
    # Browser
    firefox

    # Programs
    fuzzel
    git
    inputs.nixvim.packages.x86_64-linux.default
    solaar
    tofi
    vim

    # Terminal
    ghostty
  ];

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  system.stateVersion = "25.11";
}
