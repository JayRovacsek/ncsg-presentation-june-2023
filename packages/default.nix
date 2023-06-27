{ self, system }:
let
  pkgs = self.inputs.nixpkgs.legacyPackages.${system};
  inherit (pkgs) callPackage;
  inherit (self.packages.${system}) reveal-hugo;
  inherit (self.inputs.nixos-generators) nixosGenerate;
  formats = [
    "amazon"
    "azure"
    "do"
    "docker"
    "gce"
    "hyperv"
    "install-iso-hyperv"
    "install-iso"
    "iso"
    "kubevirt"
    "linode"
    "lxc-metadata"
    "lxc"
    "openstack"
    "proxmox-lxc"
    "proxmox"
    "qcow"
    "raw-efi"
    "raw"
    "sd-aarch64-installer"
    "sd-aarch64"
    "vagrant-virtualbox"
    "virtualbox"
    "vm-bootloader"
    "vm-nogui"
    "vm"
    "vmware"
  ];

  generator-images = builtins.foldl' (accumulator: format:
    {
      "node-microvm-${format}" = let
        modules = import ../microvms/node-microvm-modules.nix { inherit pkgs; };
      in nixosGenerate { inherit pkgs modules system format; };
    } // accumulator) { } formats;

in generator-images // {
  default = self.packages.${system}.ncsg-presentation-june-2023;
  ncsg-presentation-june-2023 =
    callPackage ./ncsg-presentation-june-2023 { inherit self reveal-hugo; };

  reveal-hugo = callPackage ./reveal-hugo { };
}
