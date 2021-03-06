{createManagedProcess, writeTextFile, lib, fcron, stateDir, runtimeDir, tmpDir, spoolDir, forceDisableUserChange, callingUser, callingGroup}:
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

  # We must override the package configuration settings to compile it with different configuration settings,
  # if we want to use a different group or run fcron as unprivileged user
  fcronPkg =
    if forceDisableUserChange then fcron.overrideAttrs (originalAttrs:
      originalAttrs // {
        configureFlags = originalAttrs.configureFlags ++ [ "--with-run-non-privileged" "--with-rootname=${callingUser}" "--with-rootgroup=${callingGroup}" "--with-username=${callingUser}" "--with-groupname=${callingGroup}" ];
      }
    )
    else if user != "fcron" || group != "fcron" then fcron.overrideAttrs (originalAttrs:
      originalAttrs // {
        configureFlags = originalAttrs.configureFlags ++ [ "--with-rootgroup=${group}" "--with-username=${user}" "--with-groupname=${group}" ];
      }
    )
    else fcron;
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

  path = [ fcronPkg ];
  process = "${fcronPkg}/bin/fcron";
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
