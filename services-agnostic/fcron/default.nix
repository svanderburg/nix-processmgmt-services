{createManagedProcess, writeTextFile, fcron, stateDir, runtimeDir, tmpDir, spoolDir, forceDisableUserChange}:
{instanceSuffix ? "", instanceName ? "fcron${instanceSuffix}"}:

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
  name = instanceName;
  inherit instanceName;
  initialize = ''
    mkdir -p ${fcronSpoolDir}
  '';
  process = "${fcron}/bin/fcron";
  args = [ "--configfile" configFile ];
  foregroundProcessExtraArgs = [ "--foreground" "--nosyslog" ];
  daemonExtraArgs = [ "--background" ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
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
