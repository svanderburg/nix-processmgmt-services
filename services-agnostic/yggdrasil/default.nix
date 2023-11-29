{ lib, createManagedProcess, runtimeDir, yggdrasil }:

{ instanceSuffix ? "", instanceName ? "yggdrasil${instanceSuffix}"
, configFile ? null }:

createManagedProcess {
  inherit instanceName;

  foregroundProcess = lib.getExe' yggdrasil "yggdrasil";
  foregroundProcessArgs = lib.lists.optionals (configFile != null)
    [ "-useconffile" configFile ];

  initialize = ''
    mkdir -p ${runtimeDir}/yggdrasil
  '';
  overrides = {
    sysvinit = { runlevels = [ 2 3 4 5 ]; };
  };
}
