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
, callingGroup ? null
, processManager
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange callingUser callingGroup processManager nix-processmgmt;
  };
in
{
  vsftpd = rec {
    dataPort = if forceDisableUserChange then 2000 else 20;
    listenPort = if forceDisableUserChange then 2001 else 21;

    pkg = constructors.simpleVsftpd {
      inherit dataPort listenPort;
      enableAnonymousUser = true;
      options = {
        dual_log_enable = "YES";
        local_enable = "YES";
        anon_world_readable_only = "NO";
      };
    };
  };

  vsftpd-secondary = rec {
    dataPort = if forceDisableUserChange then 2010 else 30;
    listenPort = if forceDisableUserChange then 2011 else 31;

    pkg = constructors.simpleVsftpd {
      inherit dataPort listenPort;
      enableAnonymousUser = true;

      instanceSuffix = "-secondary";
      options = {
        dual_log_enable = "YES";
        local_enable = "YES";
        anon_world_readable_only = "NO";
      };
    };
  };
}
