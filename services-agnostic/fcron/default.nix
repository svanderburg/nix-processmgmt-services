{createManagedProcess, writeTextFile, lib, fcron, stateDir, runtimeDir, tmpDir, spoolDir, forceDisableUserChange}:
{instanceSuffix ? "", instanceName ? "fcron${instanceSuffix}", initialize ? ""}:

let
  fcronSpoolDir = "${spoolDir}/${instanceName}";
  fcronRuntimeDir = if forceDisableUserChange then tmpDir else runtimeDir;
  fcronEtcDir = "${stateDir}/etc/${instanceName}";

  configFile = writeTextFile {
    name = "fcron.conf";
    text = ''
      fcrontabs=${fcronSpoolDir}
      pidfile=${fcronRuntimeDir}/${instanceName}.pid
      suspendfile=${fcronRuntimeDir}/${instanceName}.suspend
      fifofile=${fcronRuntimeDir}/${instanceName}.fifo
      fcronallow=${fcronEtcDir}/fcron.allow
      fcrondeny=${fcronEtcDir}/fcron.deny
    '';
  };

  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  inherit instanceName;

  initialize = ''
    mkdir -p ${fcronEtcDir}
    cp ${configFile} ${fcronEtcDir}/fcron.conf
    chmod 644 ${fcronEtcDir}/fcron.conf
    ${lib.optionalString (!forceDisableUserChange) ''
      chown root:${group} ${fcronEtcDir}/fcron.conf
    ''}
    ${initialize}
  '';

  process = "${fcron}/bin/fcron";
  args = [ "--configfile" "${fcronEtcDir}/fcron.conf" ];
  foregroundProcessExtraArgs = [ "--foreground" "--nosyslog" ];
  daemonExtraArgs = [ "--background" ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        homeDir = fcronSpoolDir;
        createHomeDir = true;
        description = "Fcron user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };
}
