{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, spoolDir ? "${stateDir}/spool"
, cacheDir ? "${stateDir}/cache"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, callingUser ? null
, processManager
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange processManager;
  };
in
rec {
  xinetd-primary = rec {
    port = if forceDisableUserChange then 6969 else 69;

    pkg = constructors.declarativeXinetd {
      instanceSuffix = "-primary";

      services = {
        tftp = {
          socket_type = "dgram";
          protocol = "udp";
          bind = "127.0.0.1";
          wait = "yes";
          user = if forceDisableUserChange then callingUser else "root";
          server = "${pkgs.inetutils}/libexec/tftpd";
          server_args = [ "-u " (if forceDisableUserChange then callingUser else "nobody") ];
          disable = "no";
          type = "UNLISTED"; # Makes it possible to bind this service to any port. Otherwise it needs to match the port in /etc/services
          inherit port;
        };
      };
    };
  };

  xinetd-secondary = rec {
    port = if forceDisableUserChange then 2323 else 23;

    pkg = constructors.declarativeXinetd {
      instanceSuffix = "-secondary";

      services = {
        telnet = {
          flags = "REUSE";
          socket_type = "stream";
          wait = "no";
          user = if forceDisableUserChange then callingUser else "root";
          server = "${pkgs.inetutils}/libexec/telnetd";
          server_args = [ "-E" "${pkgs.bashInteractive}/bin/bash" ]; # Use interactive bash as login executable, so that we can bypass logins altogether. Useful for testing.
          disable = "no";
          instances = 10;
          type = "UNLISTED"; # Makes it possible to bind this service to any port. Otherwise it needs to match the port in /etc/services
          inherit port;
        };
      };
    };
  };
}
