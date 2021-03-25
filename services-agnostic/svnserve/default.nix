{createManagedProcess, lib, subversion, runtimeDir, forceDisableUserChange}:

{ instanceSuffix ? ""
, instanceName ? "svnserve${instanceSuffix}"
, port ? 3690
, svnBaseDir
, svnGroup
, postInstall ? ""
}:

let
  pidFile = "${runtimeDir}/${instanceName}.pid";
in
createManagedProcess {
  inherit instanceName postInstall;

  initialize = ''
    mkdir -p ${svnBaseDir}
    ${lib.optionalString (!forceDisableUserChange) ''
      chgrp ${svnGroup} ${svnBaseDir}
    ''}
  '';
  process = "${subversion.out}/bin/svnserve";
  args = [ "-r" svnBaseDir "--listen-port" port "--daemon" ];
  foregroundProcessExtraArgs = ["--foreground" ];
  daemonExtraArgs = [ "--pid-file" pidFile ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
