{ lib, createManagedProcess, libDir, zerotierone }:

{ instanceSuffix ? "", instanceName ? "zerotier-one${instanceSuffix}"
, joinNetworks ? [ ], port ? 9993 }:

let ztDir = "${libDir}/${instanceName}";
in createManagedProcess {
  inherit instanceName;
  initialize = ''
    mkdir -p "${ztDir}/networks.d"
  '' + lib.strings.concatMapStrings (netId: ''
    touch "${ztDir}/networks.d/${netId}.conf"
  '') joinNetworks;
  foregroundProcess = "${zerotierone}/bin/zerotier-one";
  foregroundProcessArgs = [ "-p${toString port}" "${ztDir}" ];
  daemonExtraArgs = [ "-d" ];
  overrides = {
    sysvinit = { runlevels = [ 2 3 4 5 ]; };
  };
}
