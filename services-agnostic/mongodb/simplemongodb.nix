{createManagedProcess, lib, writeTextFile, mongodb, tmpDir, stateDir, forceDisableUserChange}:

{ instanceSuffix ? ""
, instanceName ? "mongodb${instanceSuffix}"
, bindIP ? "127.0.0.1"
, port ? 27017
, postInstall ? ""
}:

let
  mongodbDir = "${stateDir}/db/${instanceName}";
  user = instanceName;
  group = instanceName;
in
import ./default.nix {
  inherit createManagedProcess mongodb tmpDir;
} {
  inherit instanceName postInstall;
  configFile = writeTextFile {
    name = "mongodb.conf";
    text = ''
      systemLog.destination: syslog
      storage.dbPath: ${mongodbDir}
      net.bindIp: ${bindIP}
      net.port: ${toString port}
    '';
  };
  initialize = ''
    mkdir -p ${mongodbDir}
    ${lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${mongodbDir}
    ''}
  '';
}
