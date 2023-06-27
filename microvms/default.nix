{ self }:
let
  inherit (self.inputs) nixpkgs microvm;
  systems = [ "x86_64-linux" "aarch64-linux" ];
  hypervisors = [ "qemu" "cloud-hypervisor" "firecracker" "crosvm" "kvmtool" ];

in builtins.foldl' (accumulator: system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    node-microvm-modules = import ./node-microvm-modules.nix { inherit pkgs; };
  in (builtins.foldl' (acc: hypervisor:
    {
      "node-${hypervisor}-microvm-${system}" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = node-microvm-modules ++ [
          microvm.nixosModules.microvm
          {
            microvm = {
              inherit hypervisor;
              vcpu = 1;
              mem = 512;
            };
          }
        ];
      };
    } // acc) { } hypervisors) // accumulator) {

    } systems
