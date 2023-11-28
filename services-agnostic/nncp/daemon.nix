{ lib, createManagedProcess, nncp }:

{ instanceSuffix ? "", instanceName ? "nncp-daemon${instanceSuffix}"
, configfile ? "/etc/nncp.hjson", extraArgs ? [ ] }:

let
in createManagedProcess {
  inherit instanceName;
  foregroundProcess = "${nncp}/bin/nncp-daemon";
  foregroundProcessArgs = [ "-cfg" configfile ] ++ extraArgs;
  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
