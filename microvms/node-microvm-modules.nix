{ pkgs, ... }: [{
  environment.defaultPackages = [ ];
  environment.systemPackages = with pkgs; [ nodejs-slim ];

  documentation = {
    enable = false;
    dev.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };

  users.users.root.password = "";

  services = {
    getty.helpLine = ''
      Log in as "root" with an empty password.
      Type Ctrl-a c to switch to the qemu console
      and `quit` to stop the VM.
    '';
  };
  networking.hostName = "node-microvm";

  systemd.network = {
    enable = true;
    netdevs.virbr0.netdevConfig = {
      Kind = "bridge";
      Name = "virbr0";
    };
    networks.virbr0 = {
      matchConfig.Name = "virbr0";
      # Hand out IP addresses to MicroVMs.
      # Use `networkctl status virbr0` to see leases.
      networkConfig = {
        DHCPServer = true;
        IPv6SendRA = true;
      };
      addresses = [
        { addressConfig.Address = "10.0.0.1/24"; }
        { addressConfig.Address = "fd12:3456:789a::1/64"; }
      ];
      ipv6Prefixes = [{ ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64"; }];
    };
    networks.microvm-eth0 = {
      matchConfig.Name = "vm-*";
      networkConfig.Bridge = "virbr0";
    };
  };
  # Allow DHCP server
  networking.firewall = {
    allowedUDPPorts = [ 67 ];
    allowedTCPPorts = [ 80 ];
  };
  # Allow Internet access
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "virbr0" ];
  };
  system.stateVersion = "23.11";
}]
