{ lib, createManagedProcess, nncp }:

{ instanceSuffix ? "", instanceName ? "nncp-caller${instanceSuffix}"
, configfile ? "/etc/nncp.hjson", extraArgs ? [ ] }:

let
in createManagedProcess {
  inherit instanceName;
  foregroundProcess = "${nncp}/bin/nncp-caller";
  foregroundProcessArgs = [ "-cfg" configfile ] ++ extraArgs;
  overrides = {
    sysvinit = { runlevels = [ 3 4 5 ]; };
  };
}
